import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../cash/expected_cash.dart';

class ShiftAlreadyOpenException implements Exception {
  const ShiftAlreadyOpenException();
}

class NoOpenShiftException implements Exception {
  const NoOpenShiftException();
}

class StoreOption {
  const StoreOption({required this.id, required this.code, required this.name});

  factory StoreOption.fromJson(Map<String, dynamic> json) {
    return StoreOption(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String code;
  final String name;
}

class ShiftRepository {
  ShiftRepository({required Dio dio, required AppDatabase db})
    : _dio = dio,
      _db = db;

  final Dio _dio;
  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<List<StoreOption>> fetchStores() async {
    final response = await _dio.get<List<dynamic>>('/stores');
    final data = response.data;
    if (data == null) {
      return [];
    }
    return data.cast<Map<String, dynamic>>().map(StoreOption.fromJson).toList();
  }

  Future<String> openShift({
    required String storeId,
    required int openingCash,
    required String userId,
  }) async {
    final shiftId = _uuid.v4();
    final openedAt = DateTime.now();

    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.shiftsLocal)..where(
                (shift) =>
                    shift.storeId.equals(storeId) &
                    shift.userId.equals(userId) &
                    shift.closedAt.isNull(),
              ))
              .getSingleOrNull();
      if (existing != null) {
        throw const ShiftAlreadyOpenException();
      }

      await _db
          .into(_db.shiftsLocal)
          .insert(
            ShiftsLocalCompanion.insert(
              id: shiftId,
              storeId: storeId,
              userId: userId,
              openedAt: openedAt,
              openingCash: openingCash,
            ),
          );

      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'shift_open',
              payloadJson: jsonEncode({
                'id': shiftId,
                'storeId': storeId,
                'userId': userId,
                'openingCash': openingCash,
                'openedAt': openedAt.toUtc().toIso8601String(),
              }),
              createdAt: openedAt,
            ),
          );

      await _db.setMetaValue('currentStoreId', storeId);
    });

    return shiftId;
  }

  Future<ShiftsLocalData> requireOpenShift({
    required String storeId,
    required String userId,
  }) async {
    final shift =
        await (_db.select(_db.shiftsLocal)..where(
              (s) =>
                  s.storeId.equals(storeId) &
                  s.userId.equals(userId) &
                  s.closedAt.isNull(),
            ))
            .getSingleOrNull();
    if (shift == null) {
      throw const NoOpenShiftException();
    }
    return shift;
  }

  Future<ShiftCashBreakdown> breakdownForOpenShift({
    required String storeId,
    required String userId,
  }) async {
    final shift = await requireOpenShift(storeId: storeId, userId: userId);
    return breakdownForShift(shift.id, openingCash: shift.openingCash);
  }

  Future<ShiftCashBreakdown> breakdownForShift(
    String shiftId, {
    required int openingCash,
  }) async {
    final sales = await (_db.select(_db.salesLocal)
          ..where((s) => s.shiftId.equals(shiftId)))
        .get();
    var saleCash = 0;
    var saleTransfer = 0;
    for (final sale in sales) {
      saleCash += sale.cashAmount;
      saleTransfer += sale.transferAmount;
    }

    final debtPayments = await (_db.select(_db.debtLedgerLocal)
          ..where(
            (d) => d.shiftId.equals(shiftId) & d.type.equals('payment'),
          ))
        .get();
    var debtPaymentCash = 0;
    var debtPaymentTransfer = 0;
    for (final payment in debtPayments) {
      if (payment.paymentMethod == 'cash') {
        debtPaymentCash += payment.amountVnd;
      } else if (payment.paymentMethod == 'transfer') {
        debtPaymentTransfer += payment.amountVnd;
      }
    }

    final vouchers = await (_db.select(_db.cashVouchersLocal)
          ..where((v) => v.shiftId.equals(shiftId)))
        .get();
    var voucherCashIn = 0;
    var voucherCashOut = 0;
    var voucherTransferIn = 0;
    var voucherTransferOut = 0;
    for (final voucher in vouchers) {
      if (voucher.direction == 'in' && voucher.channel == 'cash') {
        voucherCashIn += voucher.amountVnd;
      } else if (voucher.direction == 'out' && voucher.channel == 'cash') {
        voucherCashOut += voucher.amountVnd;
      } else if (voucher.direction == 'in' && voucher.channel == 'transfer') {
        voucherTransferIn += voucher.amountVnd;
      } else if (voucher.direction == 'out' && voucher.channel == 'transfer') {
        voucherTransferOut += voucher.amountVnd;
      }
    }

    return computeBreakdown(
      openingCash: openingCash,
      saleCashTotal: saleCash,
      saleTransferTotal: saleTransfer,
      debtPaymentCashTotal: debtPaymentCash,
      debtPaymentTransferTotal: debtPaymentTransfer,
      voucherCashInTotal: voucherCashIn,
      voucherCashOutTotal: voucherCashOut,
      voucherTransferInTotal: voucherTransferIn,
      voucherTransferOutTotal: voucherTransferOut,
    );
  }

  Future<void> closeShift({
    required String shiftId,
    required int closingCash,
    required int expectedCashVnd,
    required int varianceVnd,
    required int transferInShiftVnd,
    String? note,
  }) async {
    final closedAt = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(
        _db.shiftsLocal,
      )..where((s) => s.id.equals(shiftId))).write(
        ShiftsLocalCompanion(
          closedAt: Value(closedAt),
          closingCash: Value(closingCash),
          note: Value(note),
          expectedCashVnd: Value(expectedCashVnd),
          varianceVnd: Value(varianceVnd),
          transferInShiftVnd: Value(transferInShiftVnd),
        ),
      );
      await _db
          .into(_db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: _uuid.v4(),
              entityType: 'shift_close',
              payloadJson: jsonEncode({
                'id': shiftId,
                'closingCash': closingCash,
                'note': note,
                'closedAt': closedAt.toUtc().toIso8601String(),
                'expectedCashVnd': expectedCashVnd,
                'varianceVnd': varianceVnd,
                'transferInShiftVnd': transferInShiftVnd,
              }),
              createdAt: closedAt,
            ),
          );
    });
  }
}
