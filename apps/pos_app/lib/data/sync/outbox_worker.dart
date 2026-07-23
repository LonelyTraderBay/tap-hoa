import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

class PushSyncResult {
  const PushSyncResult({
    required this.acceptedIds,
    required this.acceptedShiftIds,
    required this.acceptedShiftCloseIds,
    required this.rejected,
    required this.rejectedShifts,
  });

  final List<String> acceptedIds;
  final List<String> acceptedShiftIds;
  final List<String> acceptedShiftCloseIds;
  final List<RejectedSale> rejected;
  final List<RejectedSale> rejectedShifts;

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
    for (final entry in pending) {
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      switch (entry.entityType) {
        case 'shift_open':
          shiftOpens.add(payload);
        case 'sale':
          sales.add(payload);
        case 'shift_close':
          shiftCloses.add(payload);
      }
    }
    if (shiftOpens.isEmpty && sales.isEmpty && shiftCloses.isEmpty) {
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
          'shiftCloses': shiftCloses,
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
    } on DioException {
      // stay pending; do not throw to UI
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
