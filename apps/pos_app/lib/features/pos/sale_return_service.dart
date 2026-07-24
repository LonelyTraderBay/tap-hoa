import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../reports/ict_date.dart';
import '../shifts/shift_repository.dart';

class SaleReturnLineInput {
  const SaleReturnLineInput({
    required this.productId,
    required this.qty,
    required this.unitPrice,
    required this.lineRefundVnd,
  });

  final String productId;
  final Decimal qty;
  final int unitPrice;
  final int lineRefundVnd;
}

class SaleReturnService {
  SaleReturnService({
    required AppDatabase db,
    required ShiftRepository shiftRepository,
  })  : _db = db,
        _shiftRepository = shiftRepository;

  final AppDatabase _db;
  final ShiftRepository _shiftRepository;
  final _uuid = const Uuid();

  bool canReturnRole(String role) =>
      role == 'owner' || role == 'store_manager';

  bool isSameIctDay(DateTime saleAt, DateTime now) {
    final a = saleAt.toUtc().add(ictOffset);
    final b = now.toUtc().add(ictOffset);
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<String> createReturn({
    required String originalSaleId,
    required List<SaleReturnLineInput> lines,
    required int cashRefundVnd,
    required int transferRefundVnd,
    required int debtCreditVnd,
    String? note,
    String? role,
  }) async {
    final storeId = await _db.metaValue('currentStoreId');
    final userJson = await _db.metaValue('currentUser');
    if (storeId == null || userJson == null) {
      throw StateError('Missing session');
    }
    final user = jsonDecode(userJson) as Map<String, dynamic>;
    final sessionRole = role ?? user['role'] as String? ?? '';
    if (!canReturnRole(sessionRole)) {
      throw StateError('role_forbidden');
    }
    final userId = user['id'] as String;

    final sale = await (_db.select(_db.salesLocal)
          ..where((t) => t.id.equals(originalSaleId)))
        .getSingleOrNull();
    if (sale == null || sale.storeId != storeId) {
      throw StateError('sale_not_found');
    }
    final now = DateTime.now();
    if (!isSameIctDay(sale.clientCreatedAt, now)) {
      throw StateError('return_not_same_day');
    }

    final shift = await _shiftRepository.requireOpenShift(
      storeId: storeId,
      userId: userId,
    );

    final total = cashRefundVnd + transferRefundVnd + debtCreditVnd;
    final returnId = _uuid.v4();

    String formatQty(Decimal q) {
      if (q == q.truncate()) return q.truncate().toString();
      return q.toStringAsFixed(3);
    }

    await _db.transaction(() async {
      await _db.into(_db.saleReturnsLocal).insert(
        SaleReturnsLocalCompanion.insert(
          id: returnId,
          storeId: storeId,
          originalSaleId: originalSaleId,
          shiftId: Value(shift.id),
          recordedById: userId,
          cashRefundVnd: Value(cashRefundVnd),
          transferRefundVnd: Value(transferRefundVnd),
          debtCreditVnd: Value(debtCreditVnd),
          totalRefundVnd: total,
          note: Value(note),
          clientCreatedAt: now,
          updatedAt: now,
        ),
      );

      for (final line in lines) {
        final lineId = _uuid.v4();
        final qtyLabel = formatQty(line.qty);
        await _db.into(_db.saleReturnLinesLocal).insert(
          SaleReturnLinesLocalCompanion.insert(
            id: lineId,
            returnId: returnId,
            productId: line.productId,
            qty: qtyLabel,
            unitPrice: line.unitPrice,
            lineRefundVnd: line.lineRefundVnd,
          ),
        );

        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(line.productId)))
            .getSingleOrNull();
        final components = await (_db.select(_db.productComboComponents)
              ..where((t) => t.comboProductId.equals(line.productId)))
            .get();

        if (product?.kind == 'combo' && components.isNotEmpty) {
          for (final c in components) {
            final delta = line.qty * Decimal.parse(c.qtyBase);
            await _restock(
              storeId: storeId,
              productId: c.componentProductId,
              delta: delta,
              returnId: returnId,
              lineId: lineId,
              userId: userId,
              at: now,
            );
          }
        } else {
          await _restock(
            storeId: storeId,
            productId: line.productId,
            delta: line.qty,
            returnId: returnId,
            lineId: lineId,
            userId: userId,
            at: now,
          );
        }
      }

      if (debtCreditVnd > 0 && sale.customerId != null) {
        final customer = await (_db.select(_db.customersLocal)
              ..where((t) => t.id.equals(sale.customerId!)))
            .getSingleOrNull();
        if (customer != null) {
          final newBalance =
              (customer.balanceVnd - debtCreditVnd).clamp(0, 1 << 62);
          await (_db.update(_db.customersLocal)
                ..where((t) => t.id.equals(customer.id)))
              .write(
            CustomersLocalCompanion(
              balanceVnd: Value(newBalance),
              updatedAt: Value(now),
            ),
          );
          await _db.into(_db.debtLedgerLocal).insert(
            DebtLedgerLocalCompanion.insert(
              id: _uuid.v4(),
              storeId: storeId,
              customerId: customer.id,
              type: 'sale_return_credit',
              amountVnd: debtCreditVnd,
              balanceAfterVnd: newBalance,
              recordedById: userId,
              note: Value('return:$returnId'),
              clientCreatedAt: now,
              updatedAt: now,
            ),
          );
        }
      }

      await _db.into(_db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: _uuid.v4(),
          entityType: 'sale_return',
          payloadJson: jsonEncode({
            'id': returnId,
            'storeId': storeId,
            'originalSaleId': originalSaleId,
            'shiftId': shift.id,
            'cashRefundVnd': cashRefundVnd,
            'transferRefundVnd': transferRefundVnd,
            'debtCreditVnd': debtCreditVnd,
            'totalRefundVnd': total,
            'note': note,
            'clientCreatedAt': now.toUtc().toIso8601String(),
            'lines': [
              for (final line in lines)
                {
                  'productId': line.productId,
                  'qty': formatQty(line.qty),
                  'unitPrice': line.unitPrice,
                  'lineRefundVnd': line.lineRefundVnd,
                },
            ],
          }),
          createdAt: now,
        ),
      );
    });

    return returnId;
  }

  Future<void> _restock({
    required String storeId,
    required String productId,
    required Decimal delta,
    required String returnId,
    required String lineId,
    required String userId,
    required DateTime at,
  }) async {
    final stock = await (_db.select(_db.productStocks)
          ..where(
            (t) => t.productId.equals(productId) & t.storeId.equals(storeId),
          ))
        .getSingleOrNull();
    if (stock == null) throw StateError('stock_not_found');
    final next = Decimal.parse(stock.qty) + delta;
    final qtyLabel = next == next.truncate()
        ? next.truncate().toString()
        : next.toStringAsFixed(3);
    final deltaLabel = delta == delta.truncate()
        ? delta.truncate().toString()
        : delta.toStringAsFixed(3);
    await (_db.update(_db.productStocks)
          ..where(
            (t) => t.productId.equals(productId) & t.storeId.equals(storeId),
          ))
        .write(
      ProductStocksCompanion(qty: Value(qtyLabel), updatedAt: Value(at)),
    );
    await _db.into(_db.stockMovementsLocal).insert(
      StockMovementsLocalCompanion.insert(
        id: _uuid.v4(),
        storeId: storeId,
        productId: productId,
        qtyDelta: deltaLabel,
        balanceAfter: qtyLabel,
        docType: 'sale_return',
        docId: returnId,
        docLineId: Value(lineId),
        recordedById: userId,
        clientCreatedAt: at,
        updatedAt: at,
      ),
    );
  }
}
