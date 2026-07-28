import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../customers/credit_limit.dart';
import '../products/unit_conversion.dart';
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

/// Spec §6.2: khi `allowNegativeStock=true` cho phép bán dù tồn về âm,
/// nhưng vẫn phải "Cảnh báo" — đây là dữ liệu 1 dòng cảnh báo cho 1 sản
/// phẩm có tồn kho SAU bán thực sự < 0, để lớp UI phía trên (payment_sheet)
/// hiển thị cho thu ngân biết cần báo chủ kiểm kê.
class NegativeStockWarning {
  const NegativeStockWarning({
    required this.productId,
    required this.productName,
    required this.remainingQtyLabel,
  });

  final String productId;
  final String productName;

  /// Tồn kho còn lại sau khi bán, đã format và luôn âm (vd "-1", "-0.500").
  final String remainingQtyLabel;
}

class CheckoutResult {
  const CheckoutResult({
    required this.saleId,
    required this.negativeStockWarnings,
  });

  final String saleId;

  /// Rỗng ở đường đi bình thường. Chỉ có phần tử khi `allowNegativeStock`
  /// đang bật VÀ đơn này khiến tồn của ít nhất 1 dòng hàng (hoặc thành
  /// phần combo) về âm — giao dịch vẫn đã hoàn tất bình thường, đây chỉ là
  /// cảnh báo thêm, không phải lỗi.
  final List<NegativeStockWarning> negativeStockWarnings;
}

class CheckoutService {
  CheckoutService({required AppDatabase db, required ShiftRepository shiftRepository})
    : _db = db,
      _shiftRepository = shiftRepository;

  final AppDatabase _db;
  final ShiftRepository _shiftRepository;
  final _uuid = const Uuid();

  Future<CheckoutResult> complete({
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
    final warnings = <NegativeStockWarning>[];
    final outboxId = _uuid.v4();
    final clientCreatedAt = DateTime.now();
    final storeRow = await (_db.select(_db.storesLocal)
          ..where((t) => t.id.equals(storeId)))
        .getSingleOrNull();
    final allowNegativeStock = storeRow?.allowNegativeStock ?? false;

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

      final outboxLines = <Map<String, dynamic>>[];

      for (final line in draft.lines) {
        final lineId = _uuid.v4();
        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(line.productId)))
            .getSingleOrNull();
        if (product == null) {
          throw InsufficientStockException(line.productId);
        }

        final sellQty = Decimal.parse(line.qty);
        final pack = parsePackSize(product.packSize);
        final baseQty = toBaseQty(sellQty, pack);

        var unitCostVnd = 0;
        if (product.kind == 'combo') {
          final components = await (_db.select(_db.productComboComponents)
                ..where((t) => t.comboProductId.equals(product.id)))
              .get();
          if (components.isEmpty) {
            throw InsufficientStockException(line.productId);
          }
          for (final c in components) {
            final componentStock = await (_db.select(_db.productStocks)
                  ..where(
                    (t) =>
                        t.productId.equals(c.componentProductId) &
                        t.storeId.equals(storeId),
                  ))
                .getSingleOrNull();
            final componentProduct = await (_db.select(_db.products)
                  ..where((t) => t.id.equals(c.componentProductId)))
                .getSingleOrNull();
            final avg = (componentStock?.avgCostVnd ?? 0) > 0
                ? componentStock!.avgCostVnd
                : (componentProduct?.costVnd ?? 0);
            unitCostVnd +=
                (avg * (Decimal.parse(c.qtyBase).toDouble())).round();
          }
        } else {
          final stock = await (_db.select(_db.productStocks)
                ..where(
                  (t) =>
                      t.productId.equals(line.productId) &
                      t.storeId.equals(storeId),
                ))
              .getSingleOrNull();
          unitCostVnd = (stock?.avgCostVnd ?? 0) > 0
              ? stock!.avgCostVnd
              : product.costVnd;
        }

        await _db.into(_db.saleLinesLocal).insert(
          SaleLinesLocalCompanion.insert(
            id: lineId,
            saleId: saleId,
            productId: line.productId,
            qty: _formatQty(baseQty),
            unitPrice: line.unitPrice,
            discountVnd: Value(line.discountVnd),
            lineTotal: line.lineTotal,
            unitCostVnd: Value(unitCostVnd),
          ),
        );

        outboxLines.add({
          'productId': line.productId,
          'qty': _formatQty(baseQty),
          'unitPrice': line.unitPrice,
          'discountVnd': line.discountVnd,
          'lineTotal': line.lineTotal,
        });

        if (product.kind == 'combo') {
          final components = await (_db.select(_db.productComboComponents)
                ..where((t) => t.comboProductId.equals(product.id)))
              .get();
          for (final c in components) {
            final componentQty = baseQty * Decimal.parse(c.qtyBase);
            final warning = await _decrementStock(
              storeId: storeId,
              productId: c.componentProductId,
              soldQty: componentQty,
              allowNegative: allowNegativeStock,
              saleId: saleId,
              lineId: lineId,
              userId: userId,
              clientCreatedAt: clientCreatedAt,
            );
            if (warning != null) {
              warnings.add(warning);
            }
          }
        } else {
          final warning = await _decrementStock(
            storeId: storeId,
            productId: line.productId,
            soldQty: baseQty,
            allowNegative: allowNegativeStock,
            saleId: saleId,
            lineId: lineId,
            userId: userId,
            clientCreatedAt: clientCreatedAt,
          );
          if (warning != null) {
            warnings.add(warning);
          }
        }
      }

      CustomersLocalData? debtCustomer;
      if (payment.debt > 0 && customerId != null) {
        debtCustomer = await (_db.select(_db.customersLocal)
              ..where((row) => row.id.equals(customerId)))
            .getSingleOrNull();
        if (debtCustomer == null) throw StateError('customer not found');
        if (exceedsCreditLimit(
          balanceVnd: debtCustomer.balanceVnd,
          debtAmount: payment.debt,
          creditLimitVnd: debtCustomer.creditLimitVnd,
        )) {
          throw CreditLimitExceededException(
            balanceVnd: debtCustomer.balanceVnd,
            creditLimitVnd: debtCustomer.creditLimitVnd!,
            debtAmount: payment.debt,
          );
        }
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
            if (debtCustomer != null)
              'customer': {
                'id': debtCustomer.id,
                'name': debtCustomer.name,
                'phone': debtCustomer.phone,
              },
            'clientCreatedAt': clientCreatedAt.toUtc().toIso8601String(),
            'lines': outboxLines,
          }),
          createdAt: clientCreatedAt,
        ),
      );

      if (debtCustomer != null) {
        final newBalance = debtCustomer.balanceVnd + payment.debt;
        final now = DateTime.now();
        await (_db.update(_db.customersLocal)
              ..where((row) => row.id.equals(debtCustomer!.id)))
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
            customerId: debtCustomer.id,
            type: 'sale_debt',
            amountVnd: payment.debt,
            balanceAfterVnd: newBalance,
            saleId: Value(saleId),
            shiftId: Value(shift.id),
            recordedById: userId,
            clientCreatedAt: clientCreatedAt,
            updatedAt: now,
          ),
        );
      }
    });

    return CheckoutResult(saleId: saleId, negativeStockWarnings: warnings);
  }

  /// Trừ tồn kho cho 1 sản phẩm (dòng hàng thường hoặc 1 thành phần combo).
  /// Trả về `NegativeStockWarning` khi tồn SAU bán thực sự < 0 (chỉ có thể
  /// xảy ra khi `allowNegative=true` — nếu không, nhánh trên đã throw
  /// `InsufficientStockException` trước khi tới đây); ngược lại trả `null`.
  Future<NegativeStockWarning?> _decrementStock({
    required String storeId,
    required String productId,
    required Decimal soldQty,
    required bool allowNegative,
    required String saleId,
    required String lineId,
    required String userId,
    required DateTime clientCreatedAt,
  }) async {
    final stockRow = await (_db.select(_db.productStocks)..where(
          (stock) =>
              stock.productId.equals(productId) & stock.storeId.equals(storeId),
        ))
        .getSingleOrNull();
    if (stockRow == null) {
      throw InsufficientStockException(productId);
    }

    final currentQty = Decimal.parse(stockRow.qty);
    final newQty = currentQty - soldQty;
    if (newQty < Decimal.zero && !allowNegative) {
      throw InsufficientStockException(productId);
    }

    await (_db.update(_db.productStocks)..where(
          (stock) =>
              stock.productId.equals(productId) & stock.storeId.equals(storeId),
        ))
        .write(
          ProductStocksCompanion(
            qty: Value(_formatQty(newQty)),
            updatedAt: Value(DateTime.now()),
          ),
        );

    await _db.into(_db.stockMovementsLocal).insert(
      StockMovementsLocalCompanion.insert(
        id: _uuid.v4(),
        storeId: storeId,
        productId: productId,
        qtyDelta: _formatQty(-soldQty),
        balanceAfter: _formatQty(newQty),
        docType: 'sale',
        docId: saleId,
        docLineId: Value(lineId),
        recordedById: userId,
        clientCreatedAt: clientCreatedAt,
        updatedAt: clientCreatedAt,
      ),
    );

    if (newQty < Decimal.zero) {
      final product = await (_db.select(_db.products)
            ..where((t) => t.id.equals(productId)))
          .getSingleOrNull();
      return NegativeStockWarning(
        productId: productId,
        productName: product?.name ?? productId,
        remainingQtyLabel: _formatQty(newQty),
      );
    }
    return null;
  }
}
