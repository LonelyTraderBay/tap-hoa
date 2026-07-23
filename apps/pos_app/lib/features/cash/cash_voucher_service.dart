import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../shifts/shift_repository.dart';

class CashVoucherService {
  CashVoucherService({
    required AppDatabase db,
    required ShiftRepository shiftRepository,
  }) : _db = db,
       _shiftRepository = shiftRepository;

  final AppDatabase _db;
  final ShiftRepository _shiftRepository;
  final _uuid = const Uuid();

  Future<String> recordVoucher({
    required String direction,
    required String categoryId,
    required String channel,
    required int amountVnd,
    String? note,
  }) async {
    if (amountVnd <= 0) throw StateError('amount must be positive');
    if (direction != 'in' && direction != 'out') {
      throw StateError('invalid direction');
    }
    if (channel != 'cash' && channel != 'transfer') {
      throw StateError('invalid channel');
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
    final voucherId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      final category = await (_db.select(_db.cashCategoriesLocal)
            ..where((r) => r.id.equals(categoryId)))
          .getSingleOrNull();
      if (category == null) throw StateError('category not found');

      await _db.into(_db.cashVouchersLocal).insert(
        CashVouchersLocalCompanion.insert(
          id: voucherId,
          storeId: storeId,
          shiftId: shift.id,
          categoryId: categoryId,
          direction: direction,
          channel: channel,
          amountVnd: amountVnd,
          note: Value(note),
          recordedById: userId,
          clientCreatedAt: now,
          updatedAt: now,
        ),
      );
      await _db.into(_db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: _uuid.v4(),
          entityType: 'cash_voucher',
          payloadJson: jsonEncode({
            'id': voucherId,
            'storeId': storeId,
            'shiftId': shift.id,
            'categoryId': categoryId,
            'direction': direction,
            'channel': channel,
            'amountVnd': amountVnd,
            'note': note,
            'recordedById': userId,
            'clientCreatedAt': now.toUtc().toIso8601String(),
          }),
          createdAt: now,
        ),
      );
    });
    return voucherId;
  }
}
