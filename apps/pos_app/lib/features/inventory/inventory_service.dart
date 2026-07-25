import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import 'weighted_average_cost.dart';

class InventoryLineInput {
  const InventoryLineInput({
    required this.productId,
    required this.qty,
    this.unitCostVnd,
    this.systemQty,
    this.countedQty,
    this.reason,
    this.reasonNote,
  });

  final String productId;
  final Decimal qty;
  final int? unitCostVnd;
  final Decimal? systemQty;
  final Decimal? countedQty;
  final String? reason;
  final String? reasonNote;
}

String formatInventoryQty(Decimal qty) {
  if (qty == qty.truncate()) {
    return qty.truncate().toString();
  }
  return qty.toStringAsFixed(3);
}

String _purchaseOrderStatusFromLines(List<PurchaseOrderLinesLocalData> lines) {
  final anyReceived = lines.any(
    (line) => Decimal.parse(line.receivedQty) > Decimal.zero,
  );
  final allReceived = lines.every(
    (line) => Decimal.parse(line.receivedQty) >= Decimal.parse(line.qty),
  );
  if (allReceived) return 'received';
  if (anyReceived) return 'partial';
  return 'ordered';
}

class InventoryService {
  InventoryService({required AppDatabase db}) : _db = db;

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<({String storeId, String userId, String role})> _session() async {
    final storeId = await _db.metaValue('currentStoreId');
    final userJson = await _db.metaValue('currentUser');
    if (storeId == null || userJson == null) {
      throw StateError('Missing store or user session');
    }
    final user = jsonDecode(userJson) as Map<String, dynamic>;
    return (
      storeId: storeId,
      userId: user['id'] as String,
      role: user['role'] as String? ?? 'cashier',
    );
  }

  bool _isManagerOrOwner(String role) =>
      role == 'owner' || role == 'store_manager';

  Future<void> _adjustLocalStock({
    required String storeId,
    required String productId,
    required Decimal delta,
    required bool requireNonNegative,
    Decimal? setAbsolute,
  }) async {
    final allowNegative = (await _db.metaValue('allowNegativeStock')) == 'true';
    var row =
        await (_db.select(_db.productStocks)..where(
              (s) => s.productId.equals(productId) & s.storeId.equals(storeId),
            ))
            .getSingleOrNull();
    if (row == null) {
      await _db
          .into(_db.productStocks)
          .insert(
            ProductStocksCompanion.insert(
              productId: productId,
              storeId: storeId,
              qty: '0',
              minQty: '0',
              updatedAt: DateTime.now(),
            ),
          );
      row =
          await (_db.select(_db.productStocks)..where(
                (s) =>
                    s.productId.equals(productId) & s.storeId.equals(storeId),
              ))
              .getSingle();
    }
    final current = Decimal.parse(row.qty);
    final next = setAbsolute ?? (current + delta);
    if (next < Decimal.zero && requireNonNegative && !allowNegative) {
      throw StateError('insufficient_stock');
    }
    await (_db.update(_db.productStocks)..where(
          (s) => s.productId.equals(productId) & s.storeId.equals(storeId),
        ))
        .write(
          ProductStocksCompanion(
            qty: Value(formatInventoryQty(next)),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _writeMovement({
    required String storeId,
    required String productId,
    required Decimal qtyDelta,
    required String docType,
    required String docId,
    required String docLineId,
    required String recordedById,
    required DateTime clientCreatedAt,
  }) async {
    final stock =
        await (_db.select(_db.productStocks)..where(
              (s) => s.productId.equals(productId) & s.storeId.equals(storeId),
            ))
            .getSingle();
    await _db
        .into(_db.stockMovementsLocal)
        .insert(
          StockMovementsLocalCompanion.insert(
            id: _uuid.v4(),
            storeId: storeId,
            productId: productId,
            qtyDelta: formatInventoryQty(qtyDelta),
            balanceAfter: stock.qty,
            docType: docType,
            docId: docId,
            docLineId: Value(docLineId),
            recordedById: recordedById,
            clientCreatedAt: clientCreatedAt,
            updatedAt: clientCreatedAt,
          ),
        );
  }

  Future<String> createPurchaseOrder({
    required String supplierName,
    String? supplierPhone,
    String? note,
    String status = 'draft',
    required List<InventoryLineInput> lines,
  }) async {
    if (supplierName.trim().isEmpty || lines.isEmpty) {
      throw StateError('invalid_payload');
    }
    if (status != 'draft' && status != 'ordered') {
      throw StateError('invalid_status');
    }
    final session = await _session();
    final id = _uuid.v4();
    final now = DateTime.now();
    final productIds = <String>{};
    await _db.transaction(() async {
      await _db
          .into(_db.purchaseOrdersLocal)
          .insert(
            PurchaseOrdersLocalCompanion.insert(
              id: id,
              storeId: session.storeId,
              supplierName: supplierName.trim(),
              supplierPhone: Value(supplierPhone),
              status: status,
              note: Value(note),
              createdById: session.userId,
              clientCreatedAt: now,
              orderedAt: Value(status == 'ordered' ? now : null),
              updatedAt: now,
            ),
          );
      final payloadLines = <Map<String, dynamic>>[];
      for (final line in lines) {
        if (line.qty <= Decimal.zero) throw StateError('invalid_qty');
        if (!productIds.add(line.productId)) {
          throw StateError('duplicate_product');
        }
        final lineId = _uuid.v4();
        await _db
            .into(_db.purchaseOrderLinesLocal)
            .insert(
              PurchaseOrderLinesLocalCompanion.insert(
                id: lineId,
                purchaseOrderId: id,
                productId: line.productId,
                qty: formatInventoryQty(line.qty),
                unitCostVnd: Value(line.unitCostVnd),
              ),
            );
        payloadLines.add({
          'id': lineId,
          'productId': line.productId,
          'qty': formatInventoryQty(line.qty),
          'unitCostVnd': line.unitCostVnd,
        });
      }
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'purchase_order_create',
              payloadJson: jsonEncode({
                'id': id,
                'storeId': session.storeId,
                'supplierName': supplierName.trim(),
                'supplierPhone': supplierPhone,
                'status': status,
                'note': note,
                'clientCreatedAt': now.toUtc().toIso8601String(),
                'orderedAt': status == 'ordered'
                    ? now.toUtc().toIso8601String()
                    : null,
                'lines': payloadLines,
              }),
              createdAt: now,
            ),
          );
    });
    return id;
  }

  Future<void> orderPurchaseOrder(String purchaseOrderId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      final order = await (_db.select(
        _db.purchaseOrdersLocal,
      )..where((o) => o.id.equals(purchaseOrderId))).getSingleOrNull();
      if (order == null) throw StateError('not_found');
      if (order.status == 'ordered' ||
          order.status == 'partial' ||
          order.status == 'received') {
        return;
      }
      if (order.status != 'draft') throw StateError('invalid_status');
      await (_db.update(
        _db.purchaseOrdersLocal,
      )..where((o) => o.id.equals(purchaseOrderId))).write(
        PurchaseOrdersLocalCompanion(
          status: const Value('ordered'),
          orderedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'purchase_order_order',
              payloadJson: jsonEncode({
                'id': purchaseOrderId,
                'actionAt': now.toUtc().toIso8601String(),
              }),
              createdAt: now,
            ),
          );
    });
  }

  Future<void> closePurchaseOrder(String purchaseOrderId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      final order = await (_db.select(
        _db.purchaseOrdersLocal,
      )..where((o) => o.id.equals(purchaseOrderId))).getSingleOrNull();
      if (order == null) throw StateError('not_found');
      if (order.status == 'closed') return;
      if (order.status == 'received') throw StateError('invalid_status');
      await (_db.update(
        _db.purchaseOrdersLocal,
      )..where((o) => o.id.equals(purchaseOrderId))).write(
        PurchaseOrdersLocalCompanion(
          status: const Value('closed'),
          closedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'purchase_order_close',
              payloadJson: jsonEncode({
                'id': purchaseOrderId,
                'actionAt': now.toUtc().toIso8601String(),
              }),
              createdAt: now,
            ),
          );
    });
  }

  Future<String> receivePurchaseOrder({
    required String purchaseOrderId,
    required List<InventoryLineInput> lines,
    String? note,
  }) async {
    final order = await (_db.select(
      _db.purchaseOrdersLocal,
    )..where((o) => o.id.equals(purchaseOrderId))).getSingleOrNull();
    if (order == null) throw StateError('not_found');
    return recordPurchase(
      supplierName: order.supplierName,
      supplierPhone: order.supplierPhone,
      supplierId: order.supplierId,
      purchaseOrderId: order.id,
      note: note,
      lines: lines,
    );
  }

  Future<String> recordPurchase({
    required String supplierName,
    String? supplierPhone,
    String? supplierId,
    String? purchaseOrderId,
    String? note,
    required List<InventoryLineInput> lines,
  }) async {
    if (supplierName.trim().isEmpty || lines.isEmpty) {
      throw StateError('invalid_payload');
    }
    final session = await _session();
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.transaction(() async {
      PurchaseOrdersLocalData? purchaseOrder;
      final poLinesByProduct = <String, PurchaseOrderLinesLocalData>{};
      if (purchaseOrderId != null) {
        purchaseOrder = await (_db.select(
          _db.purchaseOrdersLocal,
        )..where((o) => o.id.equals(purchaseOrderId))).getSingleOrNull();
        if (purchaseOrder == null) throw StateError('purchase_order_not_found');
        if (purchaseOrder.storeId != session.storeId) {
          throw StateError('store_forbidden');
        }
        if (purchaseOrder.status == 'closed') {
          throw StateError('purchase_order_closed');
        }
        if (purchaseOrder.status == 'draft') {
          throw StateError('purchase_order_not_ordered');
        }
        final poLines = await (_db.select(
          _db.purchaseOrderLinesLocal,
        )..where((l) => l.purchaseOrderId.equals(purchaseOrderId))).get();
        for (final poLine in poLines) {
          poLinesByProduct[poLine.productId] = poLine;
        }
      }
      await _db
          .into(_db.purchaseReceiptsLocal)
          .insert(
            PurchaseReceiptsLocalCompanion.insert(
              id: id,
              storeId: session.storeId,
              supplierName: supplierName.trim(),
              supplierPhone: Value(supplierPhone),
              supplierId: Value(supplierId),
              purchaseOrderId: Value(purchaseOrderId),
              note: Value(note),
              recordedById: session.userId,
              clientCreatedAt: now,
              updatedAt: now,
            ),
          );
      final payloadLines = <Map<String, dynamic>>[];
      final updatedPoLines = <PurchaseOrderLinesLocalData>[];
      for (final line in lines) {
        if (line.qty <= Decimal.zero) throw StateError('invalid_qty');
        final poLine = poLinesByProduct[line.productId];
        if (purchaseOrder != null && poLine == null) {
          throw StateError('purchase_order_line_not_found');
        }
        final effectiveUnitCost = line.unitCostVnd ?? poLine?.unitCostVnd;
        if (poLine != null) {
          final nextReceived = Decimal.parse(poLine.receivedQty) + line.qty;
          if (nextReceived > Decimal.parse(poLine.qty)) {
            throw StateError('purchase_order_over_received');
          }
          final updated = poLine.copyWith(
            receivedQty: formatInventoryQty(nextReceived),
          );
          updatedPoLines.add(updated);
          await (_db.update(
            _db.purchaseOrderLinesLocal,
          )..where((l) => l.id.equals(poLine.id))).write(
            PurchaseOrderLinesLocalCompanion(
              receivedQty: Value(updated.receivedQty),
            ),
          );
        }
        final lineId = _uuid.v4();
        await _db
            .into(_db.purchaseReceiptLinesLocal)
            .insert(
              PurchaseReceiptLinesLocalCompanion.insert(
                id: lineId,
                receiptId: id,
                productId: line.productId,
                qty: formatInventoryQty(line.qty),
                unitCostVnd: Value(effectiveUnitCost),
              ),
            );
        await _adjustLocalStock(
          storeId: session.storeId,
          productId: line.productId,
          delta: line.qty,
          requireNonNegative: false,
        );
        await _writeMovement(
          storeId: session.storeId,
          productId: line.productId,
          qtyDelta: line.qty,
          docType: 'purchase',
          docId: id,
          docLineId: lineId,
          recordedById: session.userId,
          clientCreatedAt: now,
        );
        if (effectiveUnitCost != null) {
          final stockBefore =
              await (_db.select(_db.productStocks)..where(
                    (t) =>
                        t.productId.equals(line.productId) &
                        t.storeId.equals(session.storeId),
                  ))
                  .getSingleOrNull();
          // qty already includes receipt; recover old qty for WAC
          final newQty =
              Decimal.tryParse(stockBefore?.qty ?? '0') ?? Decimal.zero;
          final oldQty = newQty - line.qty;
          final oldAvg = stockBefore?.avgCostVnd ?? 0;
          final nextAvg = weightedAverageCost(
            oldQty: oldQty,
            oldAvgVnd: oldAvg,
            receiptQty: line.qty,
            unitCostVnd: effectiveUnitCost,
          );
          await (_db.update(_db.productStocks)..where(
                (t) =>
                    t.productId.equals(line.productId) &
                    t.storeId.equals(session.storeId),
              ))
              .write(ProductStocksCompanion(avgCostVnd: Value(nextAvg)));
          await (_db.update(
            _db.products,
          )..where((p) => p.id.equals(line.productId))).write(
            ProductsCompanion(
              costVnd: Value(effectiveUnitCost),
              updatedAt: Value(now),
            ),
          );
        }
        payloadLines.add({
          'id': lineId,
          'productId': line.productId,
          'qty': formatInventoryQty(line.qty),
          'unitCostVnd': effectiveUnitCost,
        });
      }
      if (purchaseOrder != null) {
        final currentLines = await (_db.select(
          _db.purchaseOrderLinesLocal,
        )..where((l) => l.purchaseOrderId.equals(purchaseOrderId!))).get();
        final updatedById = {for (final line in updatedPoLines) line.id: line};
        final status = _purchaseOrderStatusFromLines([
          for (final line in currentLines) updatedById[line.id] ?? line,
        ]);
        await (_db.update(
          _db.purchaseOrdersLocal,
        )..where((o) => o.id.equals(purchaseOrderId!))).write(
          PurchaseOrdersLocalCompanion(
            status: Value(status),
            updatedAt: Value(now),
          ),
        );
      }
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'purchase_receipt',
              payloadJson: jsonEncode({
                'id': id,
                'storeId': session.storeId,
                'supplierName': supplierName.trim(),
                'supplierPhone': supplierPhone,
                'supplierId': supplierId,
                'purchaseOrderId': purchaseOrderId,
                'note': note,
                'clientCreatedAt': now.toUtc().toIso8601String(),
                'lines': payloadLines,
              }),
              createdAt: now,
            ),
          );
    });
    return id;
  }

  Future<String> recordWastage({
    required String reasonCode,
    String? note,
    required List<InventoryLineInput> lines,
  }) async {
    if (lines.isEmpty) throw StateError('invalid_payload');
    final session = await _session();
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db
          .into(_db.wastageVouchersLocal)
          .insert(
            WastageVouchersLocalCompanion.insert(
              id: id,
              storeId: session.storeId,
              reasonCode: reasonCode,
              note: Value(note),
              recordedById: session.userId,
              clientCreatedAt: now,
              updatedAt: now,
            ),
          );
      final payloadLines = <Map<String, dynamic>>[];
      for (final line in lines) {
        if (line.qty <= Decimal.zero) throw StateError('invalid_qty');
        final lineId = _uuid.v4();
        await _db
            .into(_db.wastageVoucherLinesLocal)
            .insert(
              WastageVoucherLinesLocalCompanion.insert(
                id: lineId,
                wastageId: id,
                productId: line.productId,
                qty: formatInventoryQty(line.qty),
              ),
            );
        await _adjustLocalStock(
          storeId: session.storeId,
          productId: line.productId,
          delta: -line.qty,
          requireNonNegative: true,
        );
        await _writeMovement(
          storeId: session.storeId,
          productId: line.productId,
          qtyDelta: -line.qty,
          docType: 'wastage',
          docId: id,
          docLineId: lineId,
          recordedById: session.userId,
          clientCreatedAt: now,
        );
        payloadLines.add({
          'id': lineId,
          'productId': line.productId,
          'qty': formatInventoryQty(line.qty),
        });
      }
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'wastage',
              payloadJson: jsonEncode({
                'id': id,
                'storeId': session.storeId,
                'reasonCode': reasonCode,
                'note': note,
                'clientCreatedAt': now.toUtc().toIso8601String(),
                'lines': payloadLines,
              }),
              createdAt: now,
            ),
          );
    });
    return id;
  }

  Future<String> recordStocktake({
    String? note,
    required List<InventoryLineInput> lines,
  }) async {
    if (lines.isEmpty) throw StateError('invalid_payload');
    final session = await _session();
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db
          .into(_db.stocktakesLocal)
          .insert(
            StocktakesLocalCompanion.insert(
              id: id,
              storeId: session.storeId,
              note: Value(note),
              recordedById: session.userId,
              clientCreatedAt: now,
              updatedAt: now,
            ),
          );
      final payloadLines = <Map<String, dynamic>>[];
      for (final line in lines) {
        final systemQty = line.systemQty ?? Decimal.zero;
        final countedQty = line.countedQty ?? line.qty;
        final variance = countedQty - systemQty;
        final reason =
            line.reason ??
            (variance > Decimal.zero
                ? 'increase'
                : variance < Decimal.zero
                ? 'decrease'
                : 'match');
        final lineId = _uuid.v4();
        await _db
            .into(_db.stocktakeLinesLocal)
            .insert(
              StocktakeLinesLocalCompanion.insert(
                id: lineId,
                stocktakeId: id,
                productId: line.productId,
                systemQty: formatInventoryQty(systemQty),
                countedQty: formatInventoryQty(countedQty),
                varianceQty: formatInventoryQty(variance),
                reason: reason,
                reasonNote: Value(line.reasonNote),
              ),
            );
        await _adjustLocalStock(
          storeId: session.storeId,
          productId: line.productId,
          delta: variance,
          requireNonNegative: false,
          setAbsolute: countedQty,
        );
        if (variance != Decimal.zero) {
          await _writeMovement(
            storeId: session.storeId,
            productId: line.productId,
            qtyDelta: variance,
            docType: 'stocktake',
            docId: id,
            docLineId: lineId,
            recordedById: session.userId,
            clientCreatedAt: now,
          );
        }
        payloadLines.add({
          'id': lineId,
          'productId': line.productId,
          'systemQty': formatInventoryQty(systemQty),
          'countedQty': formatInventoryQty(countedQty),
          'varianceQty': formatInventoryQty(variance),
          'reason': reason,
          'reasonNote': line.reasonNote,
        });
      }
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'stocktake',
              payloadJson: jsonEncode({
                'id': id,
                'storeId': session.storeId,
                'note': note,
                'clientCreatedAt': now.toUtc().toIso8601String(),
                'lines': payloadLines,
              }),
              createdAt: now,
            ),
          );
    });
    return id;
  }

  Future<String> createTransfer({
    required String toStoreId,
    String? note,
    required List<InventoryLineInput> lines,
  }) async {
    final session = await _session();
    if (!_isManagerOrOwner(session.role)) {
      throw StateError('role_forbidden');
    }
    if (toStoreId == session.storeId || lines.isEmpty) {
      throw StateError('invalid_payload');
    }
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db
          .into(_db.stockTransfersLocal)
          .insert(
            StockTransfersLocalCompanion.insert(
              id: id,
              fromStoreId: session.storeId,
              toStoreId: toStoreId,
              status: 'draft',
              note: Value(note),
              createdById: session.userId,
              clientCreatedAt: now,
              updatedAt: now,
            ),
          );
      final payloadLines = <Map<String, dynamic>>[];
      for (final line in lines) {
        if (line.qty <= Decimal.zero) throw StateError('invalid_qty');
        final lineId = _uuid.v4();
        await _db
            .into(_db.stockTransferLinesLocal)
            .insert(
              StockTransferLinesLocalCompanion.insert(
                id: lineId,
                transferId: id,
                productId: line.productId,
                qty: formatInventoryQty(line.qty),
              ),
            );
        payloadLines.add({
          'id': lineId,
          'productId': line.productId,
          'qty': formatInventoryQty(line.qty),
        });
      }
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'stock_transfer_create',
              payloadJson: jsonEncode({
                'id': id,
                'fromStoreId': session.storeId,
                'toStoreId': toStoreId,
                'note': note,
                'clientCreatedAt': now.toUtc().toIso8601String(),
                'lines': payloadLines,
              }),
              createdAt: now,
            ),
          );
    });
    return id;
  }

  Future<void> approveTransfer(String transferId) async {
    final session = await _session();
    if (!_isManagerOrOwner(session.role)) {
      throw StateError('role_forbidden');
    }
    final now = DateTime.now();
    await _db.transaction(() async {
      final transfer = await (_db.select(
        _db.stockTransfersLocal,
      )..where((t) => t.id.equals(transferId))).getSingleOrNull();
      if (transfer == null) throw StateError('not_found');
      if (transfer.status == 'approved' || transfer.status == 'received') {
        return;
      }
      if (transfer.status != 'draft') throw StateError('invalid_status');
      final lines = await (_db.select(
        _db.stockTransferLinesLocal,
      )..where((l) => l.transferId.equals(transferId))).get();
      for (final line in lines) {
        final qty = Decimal.parse(line.qty);
        await _adjustLocalStock(
          storeId: transfer.fromStoreId,
          productId: line.productId,
          delta: -qty,
          requireNonNegative: true,
        );
        await _writeMovement(
          storeId: transfer.fromStoreId,
          productId: line.productId,
          qtyDelta: -qty,
          docType: 'transfer',
          docId: transferId,
          docLineId: line.id,
          recordedById: session.userId,
          clientCreatedAt: now,
        );
      }
      await (_db.update(
        _db.stockTransfersLocal,
      )..where((t) => t.id.equals(transferId))).write(
        StockTransfersLocalCompanion(
          status: const Value('approved'),
          approvedById: Value(session.userId),
          approvedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'stock_transfer_approve',
              payloadJson: jsonEncode({
                'id': transferId,
                'actionAt': now.toUtc().toIso8601String(),
              }),
              createdAt: now,
            ),
          );
    });
  }

  Future<void> rejectTransfer(String transferId) async {
    final session = await _session();
    if (!_isManagerOrOwner(session.role)) {
      throw StateError('role_forbidden');
    }
    final now = DateTime.now();
    await _db.transaction(() async {
      final transfer = await (_db.select(
        _db.stockTransfersLocal,
      )..where((t) => t.id.equals(transferId))).getSingleOrNull();
      if (transfer == null) throw StateError('not_found');
      if (transfer.status == 'rejected') return;
      if (transfer.status != 'draft') throw StateError('invalid_status');
      await (_db.update(
        _db.stockTransfersLocal,
      )..where((t) => t.id.equals(transferId))).write(
        StockTransfersLocalCompanion(
          status: const Value('rejected'),
          approvedById: Value(session.userId),
          approvedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'stock_transfer_reject',
              payloadJson: jsonEncode({
                'id': transferId,
                'actionAt': now.toUtc().toIso8601String(),
              }),
              createdAt: now,
            ),
          );
    });
  }

  Future<void> receiveTransfer(String transferId) async {
    final session = await _session();
    final now = DateTime.now();
    await _db.transaction(() async {
      final transfer = await (_db.select(
        _db.stockTransfersLocal,
      )..where((t) => t.id.equals(transferId))).getSingleOrNull();
      if (transfer == null) throw StateError('not_found');
      if (transfer.status == 'received') return;
      if (transfer.status != 'approved') throw StateError('invalid_status');
      if (transfer.toStoreId != session.storeId && session.role != 'owner') {
        throw StateError('store_forbidden');
      }
      final lines = await (_db.select(
        _db.stockTransferLinesLocal,
      )..where((l) => l.transferId.equals(transferId))).get();
      for (final line in lines) {
        final qty = Decimal.parse(line.qty);
        await _adjustLocalStock(
          storeId: transfer.toStoreId,
          productId: line.productId,
          delta: qty,
          requireNonNegative: false,
        );
        await _writeMovement(
          storeId: transfer.toStoreId,
          productId: line.productId,
          qtyDelta: qty,
          docType: 'transfer',
          docId: transferId,
          docLineId: line.id,
          recordedById: session.userId,
          clientCreatedAt: now,
        );
      }
      await (_db.update(
        _db.stockTransfersLocal,
      )..where((t) => t.id.equals(transferId))).write(
        StockTransfersLocalCompanion(
          status: const Value('received'),
          receivedById: Value(session.userId),
          receivedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'stock_transfer_receive',
              payloadJson: jsonEncode({
                'id': transferId,
                'actionAt': now.toUtc().toIso8601String(),
              }),
              createdAt: now,
            ),
          );
    });
  }

  Stream<List<StockMovementsLocalData>> watchMovements(String storeId) {
    return (_db.select(_db.stockMovementsLocal)
          ..where((m) => m.storeId.equals(storeId))
          ..orderBy([(m) => OrderingTerm.desc(m.clientCreatedAt)]))
        .watch();
  }

  Stream<List<StockTransfersLocalData>> watchTransfers(String storeId) {
    return (_db.select(_db.stockTransfersLocal)
          ..where(
            (t) => t.fromStoreId.equals(storeId) | t.toStoreId.equals(storeId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.clientCreatedAt)]))
        .watch();
  }

  Stream<List<PurchaseOrdersLocalData>> watchPurchaseOrders(String storeId) {
    return (_db.select(_db.purchaseOrdersLocal)
          ..where((o) => o.storeId.equals(storeId))
          ..orderBy([(o) => OrderingTerm.desc(o.clientCreatedAt)]))
        .watch();
  }
}
