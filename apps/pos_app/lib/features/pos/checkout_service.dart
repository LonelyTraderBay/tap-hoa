import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../shifts/shift_repository.dart';
import 'cart.dart';

class InsufficientStockException implements Exception {
  const InsufficientStockException(this.productId);

  final String productId;
}

class PaymentMismatchException implements Exception {
  const PaymentMismatchException(this.expected, this.actual);

  final int expected;
  final int actual;
}

class PaymentSplit {
  const PaymentSplit({this.cash = 0, this.transfer = 0, this.debt = 0});

  final int cash;
  final int transfer;
  final int debt;

  int get total => cash + transfer + debt;

  String paymentMethod() {
    final parts = <String>[];
    if (cash > 0) {
      parts.add('cash');
    }
    if (transfer > 0) {
      parts.add('transfer');
    }
    if (debt > 0) {
      parts.add('debt');
    }
    if (parts.isEmpty) {
      return 'cash';
    }
    if (parts.length == 1) {
      return parts.first;
    }
    return 'mixed';
  }
}

String _formatQty(Decimal qty) {
  if (qty == qty.truncate()) {
    return qty.truncate().toString();
  }
  return qty.toStringAsFixed(3);
}

class CheckoutService {
  CheckoutService({required AppDatabase db, required ShiftRepository shiftRepository})
    : _db = db,
      _shiftRepository = shiftRepository;

  final AppDatabase _db;
  final ShiftRepository _shiftRepository;
  final _uuid = const Uuid();

  Future<String> complete({
    required Cart cart,
    required PaymentSplit payment,
    String? customerId,
  }) async {
    if (cart.lines.isEmpty) {
      throw StateError('Cart is empty');
    }
    if (payment.total != cart.totalVnd) {
      throw PaymentMismatchException(cart.totalVnd, payment.total);
    }
    if (payment.debt > 0 && (customerId == null || customerId.isEmpty)) {
      throw StateError('customer required for debt');
    }

    final storeId = await _db.metaValue('currentStoreId');
    final userJson = await _db.metaValue('currentUser');
    if (storeId == null || userJson == null) {
      throw StateError('Missing store or user session');
    }
    final user = jsonDecode(userJson) as Map<String, dynamic>;
    final userId = user['id'] as String;

    final shift = await _shiftRepository.requireOpenShift(
      storeId: storeId,
      userId: userId,
    );

    final draft = cart.toSaleDraft();
    final saleId = _uuid.v4();
    final outboxId = _uuid.v4();
    final clientCreatedAt = DateTime.now();
    final allowNegativeStock =
        (await _db.metaValue('allowNegativeStock')) == 'true';

    await _db.transaction(() async {
      await _db.into(_db.salesLocal).insert(
        SalesLocalCompanion.insert(
          id: saleId,
          storeId: storeId,
          shiftId: shift.id,
          paymentMethod: payment.paymentMethod(),
          totalVnd: draft.totalVnd,
          cashAmount: payment.cash,
          transferAmount: payment.transfer,
          debtAmount: payment.debt,
          customerId: Value(customerId),
          clientCreatedAt: clientCreatedAt,
        ),
      );

      for (final line in draft.lines) {
        await _db.into(_db.saleLinesLocal).insert(
          SaleLinesLocalCompanion.insert(
            id: _uuid.v4(),
            saleId: saleId,
            productId: line.productId,
            qty: line.qty,
            unitPrice: line.unitPrice,
            lineTotal: line.lineTotal,
          ),
        );

        final stockRow =
            await (_db.select(_db.productStocks)..where(
                  (stock) =>
                      stock.productId.equals(line.productId) &
                      stock.storeId.equals(storeId),
                ))
                .getSingleOrNull();
        if (stockRow == null) {
          throw InsufficientStockException(line.productId);
        }

        final currentQty = Decimal.parse(stockRow.qty);
        final soldQty = Decimal.parse(line.qty);
        final newQty = currentQty - soldQty;
        if (newQty < Decimal.zero && !allowNegativeStock) {
          throw InsufficientStockException(line.productId);
        }

        await (_db.update(_db.productStocks)..where(
              (stock) =>
                  stock.productId.equals(line.productId) &
                  stock.storeId.equals(storeId),
            ))
            .write(
              ProductStocksCompanion(
                qty: Value(_formatQty(newQty)),
                updatedAt: Value(DateTime.now()),
              ),
            );
      }

      await _db.into(_db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: outboxId,
          entityType: 'sale',
          payloadJson: jsonEncode({
            'id': saleId,
            'storeId': storeId,
            'shiftId': shift.id,
            'soldById': userId,
            'paymentMethod': payment.paymentMethod(),
            'cashAmount': payment.cash,
            'transferAmount': payment.transfer,
            'debtAmount': payment.debt,
            'discountVnd': draft.discountVnd,
            'totalVnd': draft.totalVnd,
            'customerId': customerId,
            'clientCreatedAt': clientCreatedAt.toUtc().toIso8601String(),
            'lines': [
              for (final line in draft.lines)
                {
                  'productId': line.productId,
                  'qty': line.qty,
                  'unitPrice': line.unitPrice,
                  'lineTotal': line.lineTotal,
                },
            ],
          }),
          createdAt: clientCreatedAt,
        ),
      );

      if (payment.debt > 0 && customerId != null) {
        final customer = await (_db.select(_db.customersLocal)
              ..where((row) => row.id.equals(customerId)))
            .getSingleOrNull();
        if (customer != null) {
          await (_db.update(_db.customersLocal)
                ..where((row) => row.id.equals(customerId)))
              .write(
            CustomersLocalCompanion(
              balanceVnd: Value(customer.balanceVnd + payment.debt),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    });

    return saleId;
  }
}
