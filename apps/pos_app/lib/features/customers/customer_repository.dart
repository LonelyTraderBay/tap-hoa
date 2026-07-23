import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';

class CustomerRecord {
  const CustomerRecord({
    required this.id,
    required this.name,
    this.phone,
    required this.balanceVnd,
    this.creditLimitVnd,
  });

  final String id;
  final String name;
  final String? phone;
  final int balanceVnd;
  final int? creditLimitVnd;
}

class CustomerRepository {
  CustomerRepository({required AppDatabase db, required Dio dio})
    : _db = db,
      _dio = dio;

  final AppDatabase _db;
  final Dio _dio;
  final _uuid = const Uuid();

  Stream<List<CustomerRecord>> watchWithDebt() {
    return (_db.select(_db.customersLocal)
          ..where((row) => row.balanceVnd.isBiggerThanValue(0))
          ..orderBy([
            (row) => OrderingTerm.desc(row.balanceVnd),
            (row) => OrderingTerm.asc(row.name),
          ]))
        .watch()
        .map(
          (rows) => rows
              .map(_toRecord)
              .toList(),
        );
  }

  Stream<CustomerRecord?> watchById(String customerId) {
    return (_db.select(_db.customersLocal)
          ..where((row) => row.id.equals(customerId)))
        .watch()
        .map((rows) => rows.isEmpty ? null : _toRecord(rows.first));
  }

  Stream<List<DebtLedgerLocalData>> watchLedger(String customerId) {
    return (_db.select(_db.debtLedgerLocal)
          ..where((row) => row.customerId.equals(customerId))
          ..orderBy([(row) => OrderingTerm.desc(row.clientCreatedAt)]))
        .watch();
  }

  CustomerRecord _toRecord(CustomersLocalData row) {
    return CustomerRecord(
      id: row.id,
      name: row.name,
      phone: row.phone,
      balanceVnd: row.balanceVnd,
      creditLimitVnd: row.creditLimitVnd,
    );
  }

  Future<List<CustomerRecord>> searchByName(String query) async {
    final trimmed = query.trim();
    final rows =
        await (_db.select(_db.customersLocal)
              ..where(
                (row) => trimmed.isEmpty
                    ? const Constant(true)
                    : row.name.like('%$trimmed%'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();
    return rows
        .map(
          (row) => CustomerRecord(
            id: row.id,
            name: row.name,
            phone: row.phone,
            balanceVnd: row.balanceVnd,
            creditLimitVnd: row.creditLimitVnd,
          ),
        )
        .toList();
  }

  Future<CustomerRecord> create({required String name, String? phone}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final trimmedName = name.trim();
    final trimmedPhone = phone?.trim();

    await _db
        .into(_db.customersLocal)
        .insert(
          CustomersLocalCompanion.insert(
            id: id,
            name: trimmedName,
            phone: Value(trimmedPhone?.isEmpty ?? true ? null : trimmedPhone),
            balanceVnd: const Value(0),
            creditLimitVnd: const Value(null),
            updatedAt: now,
          ),
        );

    try {
      final storeId = await _db.metaValue('currentStoreId');
      if (storeId == null || storeId.isEmpty) {
        return CustomerRecord(
          id: id,
          name: trimmedName,
          phone: trimmedPhone?.isEmpty ?? true ? null : trimmedPhone,
          balanceVnd: 0,
        );
      }
      await _dio.post(
        '/customers',
        data: {
          'id': id,
          'storeId': storeId,
          'name': trimmedName,
          'phone': trimmedPhone?.isEmpty ?? true ? null : trimmedPhone,
        },
      );
    } catch (_) {
      // Offline create is allowed; sync will upsert on next online call.
    }

    return CustomerRecord(
      id: id,
      name: trimmedName,
      phone: trimmedPhone?.isEmpty ?? true ? null : trimmedPhone,
      balanceVnd: 0,
    );
  }

  Future<void> updateCreditLimit({
    required String customerId,
    required int? creditLimitVnd,
  }) async {
    final now = DateTime.now();
    final row = await (_db.select(_db.customersLocal)
          ..where((r) => r.id.equals(customerId)))
        .getSingle();
    await (_db.update(_db.customersLocal)..where((r) => r.id.equals(customerId)))
        .write(
      CustomersLocalCompanion(
        creditLimitVnd: Value(creditLimitVnd),
        updatedAt: Value(now),
      ),
    );
    final storeId = await _db.metaValue('currentStoreId');
    if (storeId == null) return;
    await _db.into(_db.outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        id: _uuid.v4(),
        entityType: 'customer_upsert',
        payloadJson: jsonEncode({
          'id': row.id,
          'storeId': storeId,
          'name': row.name,
          'phone': row.phone,
          'creditLimitVnd': creditLimitVnd,
        }),
        createdAt: now,
      ),
    );
  }
}
