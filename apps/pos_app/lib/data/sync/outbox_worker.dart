import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

class ClosedShiftSnapshot {
  const ClosedShiftSnapshot({
    required this.id,
    required this.expectedCashVnd,
    required this.varianceVnd,
    required this.transferInShiftVnd,
    required this.closingCash,
    required this.closedAt,
    this.note,
  });

  final String id;
  final int expectedCashVnd;
  final int varianceVnd;
  final int transferInShiftVnd;
  final int closingCash;
  final DateTime closedAt;
  final String? note;

  factory ClosedShiftSnapshot.fromJson(Map<String, dynamic> json) {
    return ClosedShiftSnapshot(
      id: json['id'] as String,
      expectedCashVnd: json['expectedCashVnd'] as int,
      varianceVnd: json['varianceVnd'] as int,
      transferInShiftVnd: json['transferInShiftVnd'] as int,
      closingCash: json['closingCash'] as int,
      closedAt: DateTime.parse(json['closedAt'] as String),
      note: json['note'] as String?,
    );
  }
}

class PushSyncResult {
  const PushSyncResult({
    required this.acceptedIds,
    required this.acceptedShiftIds,
    required this.acceptedShiftCloseIds,
    required this.closedShifts,
    required this.acceptedDebtPaymentIds,
    required this.acceptedCashVoucherIds,
    required this.acceptedCustomerUpsertIds,
    required this.rejected,
    required this.rejectedShifts,
    required this.rejectedDebtPayments,
    required this.rejectedCashVouchers,
  });

  final List<String> acceptedIds;
  final List<String> acceptedShiftIds;
  final List<String> acceptedShiftCloseIds;
  final List<ClosedShiftSnapshot> closedShifts;
  final List<String> acceptedDebtPaymentIds;
  final List<String> acceptedCashVoucherIds;
  final List<String> acceptedCustomerUpsertIds;
  final List<RejectedSale> rejected;
  final List<RejectedSale> rejectedShifts;
  final List<RejectedSale> rejectedDebtPayments;
  final List<RejectedSale> rejectedCashVouchers;

  factory PushSyncResult.fromJson(Map<String, dynamic> json) {
    final rejected = (json['rejected'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return PushSyncResult(
      acceptedIds: (json['acceptedIds'] as List<dynamic>? ?? [])
          .map((id) => id as String)
          .toList(),
      acceptedShiftIds: (json['acceptedShiftIds'] as List<dynamic>? ?? [])
          .map((id) => id as String)
          .toList(),
      acceptedShiftCloseIds:
          (json['acceptedShiftCloseIds'] as List<dynamic>? ?? [])
              .map((id) => id as String)
              .toList(),
      closedShifts: [
        for (final item
            in (json['closedShifts'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>())
          ClosedShiftSnapshot.fromJson(item),
      ],
      acceptedDebtPaymentIds:
          (json['acceptedDebtPaymentIds'] as List<dynamic>? ?? [])
              .map((id) => id as String)
              .toList(),
      acceptedCashVoucherIds:
          (json['acceptedCashVoucherIds'] as List<dynamic>? ?? [])
              .map((id) => id as String)
              .toList(),
      acceptedCustomerUpsertIds:
          (json['acceptedCustomerUpsertIds'] as List<dynamic>? ?? [])
              .map((id) => id as String)
              .toList(),
      rejected: [
        for (final item in rejected)
          RejectedSale(
            id: item['id'] as String,
            reason: item['reason'] as String,
          ),
      ],
      rejectedShifts: [
        for (final item
            in (json['rejectedShifts'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>())
          RejectedSale(
            id: item['id'] as String,
            reason: item['reason'] as String,
          ),
      ],
      rejectedDebtPayments: [
        for (final item
            in (json['rejectedDebtPayments'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>())
          RejectedSale(
            id: item['id'] as String,
            reason: item['reason'] as String,
          ),
      ],
      rejectedCashVouchers: [
        for (final item
            in (json['rejectedCashVouchers'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>())
          RejectedSale(
            id: item['id'] as String,
            reason: item['reason'] as String,
          ),
      ],
    );
  }
}

class RejectedSale {
  const RejectedSale({required this.id, required this.reason});

  final String id;
  final String reason;
}

class OutboxWorker {
  OutboxWorker({required AppDatabase db, required Dio dio})
    : _db = db,
      _dio = dio;

  final AppDatabase _db;
  final Dio _dio;
  final _uuid = const Uuid();

  Future<void> tick() async {
    final pending = await _db.pendingOutbox(limit: 50);
    final sales = <Map<String, dynamic>>[];
    final shiftOpens = <Map<String, dynamic>>[];
    final shiftCloses = <Map<String, dynamic>>[];
    final debtPayments = <Map<String, dynamic>>[];
    final cashVouchers = <Map<String, dynamic>>[];
    final customerUpserts = <Map<String, dynamic>>[];
    for (final entry in pending) {
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      switch (entry.entityType) {
        case 'shift_open':
          shiftOpens.add(payload);
        case 'sale':
          sales.add(payload);
        case 'shift_close':
          shiftCloses.add(payload);
        case 'debt_payment':
          debtPayments.add(payload);
        case 'cash_voucher':
          cashVouchers.add(payload);
        case 'customer_upsert':
          customerUpserts.add(payload);
      }
    }
    if (shiftOpens.isEmpty &&
        sales.isEmpty &&
        shiftCloses.isEmpty &&
        debtPayments.isEmpty &&
        cashVouchers.isEmpty &&
        customerUpserts.isEmpty) {
      return;
    }

    try {
      final deviceId = await _deviceId();
      final response = await _dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: {
          'deviceId': deviceId,
          'shiftOpens': shiftOpens,
          'sales': sales,
          'cashVouchers': cashVouchers,
          'debtPayments': debtPayments,
          'shiftCloses': shiftCloses,
          'customerUpserts': customerUpserts,
        },
      );
      final data = response.data;
      if (data == null) {
        return;
      }
      final result = PushSyncResult.fromJson(data);
      await _db.markOutboxEntitiesDone('shift_open', result.acceptedShiftIds);
      await _db.markOutboxDone(result.acceptedIds);
      await _db.markOutboxEntitiesDone(
        'shift_close',
        result.acceptedShiftCloseIds,
      );
      await _applyClosedShiftSnapshots(result.closedShifts);
      await _db.markOutboxEntitiesDone(
        'debt_payment',
        result.acceptedDebtPaymentIds,
      );
      await _db.markOutboxEntitiesDone(
        'cash_voucher',
        result.acceptedCashVoucherIds,
      );
      await _db.markOutboxEntitiesDone(
        'customer_upsert',
        result.acceptedCustomerUpsertIds,
      );
      for (final rejected in result.rejected) {
        await _db.markOutboxError(
          rejected.id,
          rejected.reason,
          entityType: 'sale',
        );
      }
      for (final rejected in result.rejectedShifts) {
        await _db.markOutboxError(rejected.id, rejected.reason);
      }
      for (final rejected in result.rejectedDebtPayments) {
        await _db.markOutboxError(
          rejected.id,
          rejected.reason,
          entityType: 'debt_payment',
        );
      }
      for (final rejected in result.rejectedCashVouchers) {
        await _db.markOutboxError(
          rejected.id,
          rejected.reason,
          entityType: 'cash_voucher',
        );
      }
    } on DioException {
      // stay pending; do not throw to UI
    }
  }

  Future<void> _applyClosedShiftSnapshots(
    List<ClosedShiftSnapshot> snapshots,
  ) async {
    for (final snapshot in snapshots) {
      await (_db.update(_db.shiftsLocal)..where((s) => s.id.equals(snapshot.id)))
          .write(
        ShiftsLocalCompanion(
          closedAt: Value(snapshot.closedAt),
          closingCash: Value(snapshot.closingCash),
          note: Value(snapshot.note),
          expectedCashVnd: Value(snapshot.expectedCashVnd),
          varianceVnd: Value(snapshot.varianceVnd),
          transferInShiftVnd: Value(snapshot.transferInShiftVnd),
        ),
      );
    }
  }

  Future<String> _deviceId() async {
    final existing = await _db.metaValue('deviceId');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final id = _uuid.v4();
    await _db.setMetaValue('deviceId', id);
    return id;
  }
}
