import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

class PushSyncResult {
  const PushSyncResult({
    required this.acceptedIds,
    required this.rejected,
  });

  final List<String> acceptedIds;
  final List<RejectedSale> rejected;

  factory PushSyncResult.fromJson(Map<String, dynamic> json) {
    final rejected = (json['rejected'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return PushSyncResult(
      acceptedIds: (json['acceptedIds'] as List<dynamic>? ?? [])
          .map((id) => id as String)
          .toList(),
      rejected: [
        for (final item in rejected)
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
    for (final entry in pending) {
      if (entry.entityType != 'sale') {
        continue;
      }
      sales.add(jsonDecode(entry.payloadJson) as Map<String, dynamic>);
    }
    if (sales.isEmpty) {
      return;
    }

    try {
      final deviceId = await _deviceId();
      final response = await _dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: {'deviceId': deviceId, 'sales': sales},
      );
      final data = response.data;
      if (data == null) {
        return;
      }
      final result = PushSyncResult.fromJson(data);
      await _db.markOutboxDone(result.acceptedIds);
      for (final rejected in result.rejected) {
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
