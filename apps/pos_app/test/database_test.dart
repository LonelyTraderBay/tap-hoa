import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/local/database.dart';

void main() {
  test('outbox rejects unsupported status', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(
      () => db
          .into(db.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: 'entry-1',
              entityType: 'sale',
              payloadJson: '{}',
              createdAt: DateTime(2026),
              status: const Value('queued'),
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });
}
