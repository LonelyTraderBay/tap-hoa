import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../shifts/shift_repository.dart';

class DebtPaymentService {
  DebtPaymentService({required AppDatabase db, required ShiftRepository shiftRepository})
    : _db = db,
      _shiftRepository = shiftRepository;

  final AppDatabase _db;
  final ShiftRepository _shiftRepository;
  final _uuid = const Uuid();

  Future<String> recordPayment({
    required String customerId,
    required int amountVnd,
    required String paymentMethod,
    String? note,
  }) async {
    if (amountVnd <= 0) throw StateError('amount must be positive');
    if (paymentMethod != 'cash' && paymentMethod != 'transfer') {
      throw StateError('invalid payment method');
    }
    final storeId = await _db.metaValue('currentStoreId');
    final userJson = await _db.metaValue('currentUser');
    if (storeId == null || userJson == null) {
      throw StateError('Missing store or user session');
    }
    final userId = (jsonDecode(userJson) as Map<String, dynamic>)['id'] as String;
    final shift = await _shiftRepository.requireOpenShift(
      storeId: storeId,
      userId: userId,
    );
    final paymentId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      final customer = await (_db.select(_db.customersLocal)
            ..where((r) => r.id.equals(customerId)))
          .getSingleOrNull();
      if (customer == null) throw StateError('customer not found');
      if (amountVnd > customer.balanceVnd) {
        throw StateError('payment exceeds balance');
      }
      final newBalance = customer.balanceVnd - amountVnd;
      await (_db.update(_db.customersLocal)..where((r) => r.id.equals(customerId)))
          .write(
        CustomersLocalCompanion(
          balanceVnd: Value(newBalance),
          updatedAt: Value(now),
        ),
      );
      await _db.into(_db.debtLedgerLocal).insert(
        DebtLedgerLocalCompanion.insert(
          id: paymentId,
          storeId: storeId,
          customerId: customerId,
          type: 'payment',
          amountVnd: amountVnd,
          balanceAfterVnd: newBalance,
          shiftId: Value(shift.id),
          recordedById: userId,
          paymentMethod: Value(paymentMethod),
          note: Value(note),
          clientCreatedAt: now,
          updatedAt: now,
        ),
      );
      await _db.into(_db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: _uuid.v4(),
          entityType: 'debt_payment',
          payloadJson: jsonEncode({
            'id': paymentId,
            'storeId': storeId,
            'customerId': customerId,
            'amountVnd': amountVnd,
            'paymentMethod': paymentMethod,
            'note': note,
            'shiftId': shift.id,
            'clientCreatedAt': now.toUtc().toIso8601String(),
            'recordedById': userId,
          }),
          createdAt: now,
        ),
      );
    });
    return paymentId;
  }
}
