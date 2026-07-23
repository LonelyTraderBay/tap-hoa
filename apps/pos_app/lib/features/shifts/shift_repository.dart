import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';

class ShiftAlreadyOpenException implements Exception {
  const ShiftAlreadyOpenException();
}

class NoOpenShiftException implements Exception {
  const NoOpenShiftException();
}

class StoreOption {
  const StoreOption({
    required this.id,
    required this.code,
    required this.name,
  });

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
    return data
        .cast<Map<String, dynamic>>()
        .map(StoreOption.fromJson)
        .toList();
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

      await _db.into(_db.shiftsLocal).insert(
        ShiftsLocalCompanion.insert(
          id: shiftId,
          storeId: storeId,
          userId: userId,
          openedAt: openedAt,
          openingCash: openingCash,
        ),
      );

      await _db.into(_db.outboxEntries).insert(
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

  Future<void> closeShift({
    required String shiftId,
    required int closingCash,
    String? note,
  }) async {
    await (_db.update(_db.shiftsLocal)..where((s) => s.id.equals(shiftId)))
        .write(
          ShiftsLocalCompanion(
            closedAt: Value(DateTime.now()),
            closingCash: Value(closingCash),
            note: Value(note),
          ),
        );
  }
}
