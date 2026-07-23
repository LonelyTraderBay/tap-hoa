import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    ProductStocks,
    OutboxEntries,
    SalesLocal,
    SaleLinesLocal,
    ShiftsLocal,
    StoresLocal,
    MetaLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  Future<String?> metaValue(String key) async {
    final row = await (select(
      metaLocal,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMetaValue(String key, String value) {
    return into(metaLocal).insertOnConflictUpdate(
      MetaLocalCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'tap_hoa_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
