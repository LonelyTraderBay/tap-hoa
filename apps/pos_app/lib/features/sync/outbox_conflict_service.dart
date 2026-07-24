import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../data/local/database.dart';
import '../../data/sync/outbox_worker.dart';

class OutboxConflictService {
  OutboxConflictService({required AppDatabase db, required OutboxWorker worker})
    : _db = db,
      _worker = worker;

  final AppDatabase _db;
  final OutboxWorker _worker;

  Future<List<OutboxEntry>> listErrors() => _db.listOutboxErrors();

  Future<void> retry(String outboxRowId) async {
    await _db.requeueOutbox(outboxRowId);
    await _worker.tick();
  }

  Future<void> retryAll() async {
    final errors = await _db.listOutboxErrors();
    for (final entry in errors) {
      await _db.requeueOutbox(entry.id);
    }
    if (errors.isNotEmpty) {
      await _worker.tick();
    }
  }

  Future<void> saveRawJson(String outboxRowId, String jsonText) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('payload must be a JSON object');
    }
    await _db.transaction(() async {
      await _db.updateOutboxPayload(outboxRowId, jsonText);
      await _db.requeueOutbox(outboxRowId);
    });
    await _worker.tick();
  }

  Future<void> saveProductUpsertIdentity({
    required String outboxRowId,
    required String sku,
    String? barcode,
  }) async {
    await _db.transaction(() async {
      final entry = await (_db.select(_db.outboxEntries)
            ..where((row) => row.id.equals(outboxRowId)))
          .getSingle();
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      final productId = payload['id'] as String?;
      if (productId == null) {
        throw StateError('missing product id in payload');
      }

      payload['sku'] = sku;
      payload['barcode'] = barcode;

      await (_db.update(_db.products)..where((row) => row.id.equals(productId)))
          .write(
        ProductsCompanion(
          sku: Value(sku),
          barcode: Value(barcode),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _db.updateOutboxPayload(outboxRowId, jsonEncode(payload));
      await _db.requeueOutbox(outboxRowId);
    });
    await _worker.tick();
  }

  /// Returns `true` when local sale/wastage tables were updated alongside payload.
  Future<bool> saveInsufficientStockQtys({
    required String outboxRowId,
    required Map<String, String> productIdToQty,
  }) async {
    final entry = await (_db.select(_db.outboxEntries)
          ..where((row) => row.id.equals(outboxRowId)))
        .getSingle();

    switch (entry.entityType) {
      case 'sale':
        return _saveSaleQtys(entry, productIdToQty);
      case 'wastage':
        return _saveWastageQtys(entry, productIdToQty);
      case 'stock_transfer_create':
      case 'stock_transfer_approve':
      case 'stock_transfer_reject':
      case 'stock_transfer_receive':
        throw StateError('use_raw_json');
      default:
        return _savePayloadOnlyQtys(entry, productIdToQty);
    }
  }

  Future<bool> _savePayloadOnlyQtys(
    OutboxEntry entry,
    Map<String, String> productIdToQty,
  ) async {
    await _db.transaction(() async {
      final payload = _updatePayloadLineQtys(entry, productIdToQty);
      await _db.updateOutboxPayload(entry.id, jsonEncode(payload));
      await _db.requeueOutbox(entry.id);
    });
    await _worker.tick();
    return false;
  }

  Future<bool> _saveSaleQtys(
    OutboxEntry entry,
    Map<String, String> productIdToQty,
  ) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final saleId = payload['id'] as String?;
    final storeId = payload['storeId'] as String?;
    if (saleId == null || storeId == null) {
      return _savePayloadOnlyQtys(entry, productIdToQty);
    }

    var localSynced = true;
    await _db.transaction(() async {
      final lines = (payload['lines'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      var totalVnd = 0;

      for (final line in lines) {
        final productId = line['productId'] as String?;
        if (productId == null || !productIdToQty.containsKey(productId)) {
          totalVnd += line['lineTotal'] as int? ?? 0;
          continue;
        }

        final newQty = Decimal.parse(productIdToQty[productId]!);
        if (newQty <= Decimal.zero) {
          throw StateError('invalid_qty');
        }

        final unitPrice = line['unitPrice'] as int? ?? 0;
        final lineTotal = (newQty * Decimal.fromInt(unitPrice))
            .round()
            .toBigInt()
            .toInt();
        line['qty'] = _formatQty(newQty);
        line['lineTotal'] = lineTotal;
        totalVnd += lineTotal;

        final localLine =
            await (_db.select(_db.saleLinesLocal)..where(
                  (row) =>
                      row.saleId.equals(saleId) &
                      row.productId.equals(productId),
                ))
                .getSingleOrNull();
        if (localLine == null) {
          localSynced = false;
          continue;
        }

        final oldQty = Decimal.parse(localLine.qty);
        final delta = newQty - oldQty;

        await (_db.update(_db.saleLinesLocal)
              ..where((row) => row.id.equals(localLine.id)))
            .write(
          SaleLinesLocalCompanion(
            qty: Value(_formatQty(newQty)),
            lineTotal: Value(lineTotal),
          ),
        );

        final stockRow =
            await (_db.select(_db.productStocks)..where(
                  (stock) =>
                      stock.productId.equals(productId) &
                      stock.storeId.equals(storeId),
                ))
                .getSingleOrNull();
        if (stockRow == null) {
          localSynced = false;
          continue;
        }

        final stockQty = Decimal.parse(stockRow.qty) - delta;
        await (_db.update(_db.productStocks)..where(
              (stock) =>
                  stock.productId.equals(productId) &
                  stock.storeId.equals(storeId),
            ))
            .write(
          ProductStocksCompanion(
            qty: Value(_formatQty(stockQty)),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      payload['totalVnd'] = totalVnd;
      _rebalanceSalePayments(payload, totalVnd);

      await (_db.update(_db.salesLocal)..where((row) => row.id.equals(saleId)))
          .write(
        SalesLocalCompanion(
          totalVnd: Value(totalVnd),
          cashAmount: Value(payload['cashAmount'] as int? ?? 0),
          transferAmount: Value(payload['transferAmount'] as int? ?? 0),
          debtAmount: Value(payload['debtAmount'] as int? ?? 0),
        ),
      );

      await _db.updateOutboxPayload(entry.id, jsonEncode(payload));
      await _db.requeueOutbox(entry.id);
    });
    await _worker.tick();
    return localSynced;
  }

  Future<bool> _saveWastageQtys(
    OutboxEntry entry,
    Map<String, String> productIdToQty,
  ) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final wastageId = payload['id'] as String?;
    final storeId = payload['storeId'] as String?;
    if (wastageId == null || storeId == null) {
      return _savePayloadOnlyQtys(entry, productIdToQty);
    }

    var localSynced = true;
    await _db.transaction(() async {
      final lines = (payload['lines'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      for (final line in lines) {
        final productId = line['productId'] as String?;
        if (productId == null || !productIdToQty.containsKey(productId)) {
          continue;
        }

        final newQty = Decimal.parse(productIdToQty[productId]!);
        if (newQty <= Decimal.zero) {
          throw StateError('invalid_qty');
        }

        line['qty'] = _formatQty(newQty);

        final localLine =
            await (_db.select(_db.wastageVoucherLinesLocal)..where(
                  (row) =>
                      row.wastageId.equals(wastageId) &
                      row.productId.equals(productId),
                ))
                .getSingleOrNull();
        if (localLine == null) {
          localSynced = false;
          continue;
        }

        final oldQty = Decimal.parse(localLine.qty);
        final delta = newQty - oldQty;

        await (_db.update(_db.wastageVoucherLinesLocal)
              ..where((row) => row.id.equals(localLine.id)))
            .write(
          WastageVoucherLinesLocalCompanion(qty: Value(_formatQty(newQty))),
        );

        final stockRow =
            await (_db.select(_db.productStocks)..where(
                  (stock) =>
                      stock.productId.equals(productId) &
                      stock.storeId.equals(storeId),
                ))
                .getSingleOrNull();
        if (stockRow == null) {
          localSynced = false;
          continue;
        }

        // Wastage decreases stock; lowering wastage qty restores stock.
        final stockQty = Decimal.parse(stockRow.qty) - delta;
        await (_db.update(_db.productStocks)..where(
              (stock) =>
                  stock.productId.equals(productId) &
                  stock.storeId.equals(storeId),
            ))
            .write(
          ProductStocksCompanion(
            qty: Value(_formatQty(stockQty)),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      await _db.updateOutboxPayload(entry.id, jsonEncode(payload));
      await _db.requeueOutbox(entry.id);
    });
    await _worker.tick();
    return localSynced;
  }

  Map<String, dynamic> _updatePayloadLineQtys(
    OutboxEntry entry,
    Map<String, String> productIdToQty,
  ) {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final lines = (payload['lines'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    for (final line in lines) {
      final productId = line['productId'] as String?;
      if (productId == null || !productIdToQty.containsKey(productId)) {
        continue;
      }
      final newQty = Decimal.parse(productIdToQty[productId]!);
      if (newQty <= Decimal.zero) {
        throw StateError('invalid_qty');
      }
      line['qty'] = _formatQty(newQty);
      if (line.containsKey('unitPrice')) {
        final unitPrice = line['unitPrice'] as int? ?? 0;
        line['lineTotal'] = (newQty * Decimal.fromInt(unitPrice))
            .round()
            .toBigInt()
            .toInt();
      }
    }
    if (entry.entityType == 'sale') {
      final totalVnd = lines.fold<int>(
        0,
        (sum, line) => sum + (line['lineTotal'] as int? ?? 0),
      );
      payload['totalVnd'] = totalVnd;
      _rebalanceSalePayments(payload, totalVnd);
    }
    return payload;
  }

  /// When line totals change, keep payment fields consistent for retry.
  /// If split no longer matches total, collapse to cash-only for simplicity.
  void _rebalanceSalePayments(Map<String, dynamic> payload, int totalVnd) {
    final cash = payload['cashAmount'] as int? ?? 0;
    final transfer = payload['transferAmount'] as int? ?? 0;
    final debt = payload['debtAmount'] as int? ?? 0;
    if (cash + transfer + debt != totalVnd) {
      payload['cashAmount'] = totalVnd;
      payload['transferAmount'] = 0;
      payload['debtAmount'] = 0;
      if (totalVnd == 0) {
        payload['paymentMethod'] = 'cash';
      }
    }
  }

  String _formatQty(Decimal qty) {
    if (qty == qty.truncate()) {
      return qty.truncate().toString();
    }
    return qty.toStringAsFixed(3);
  }
}
