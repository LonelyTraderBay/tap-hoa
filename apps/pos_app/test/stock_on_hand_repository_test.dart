import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/reports/stock_on_hand_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AppDatabase db;
  late MockDio dio;
  late StockOnHandRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = MockDio();
    repository = StockOnHandRepository(dio: dio, db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedStock({
    required String productId,
    required String sku,
    required String name,
    required String qty,
    String minQty = '5',
    int costVnd = 1000,
    bool active = true,
    String storeId = 'store-1',
  }) async {
    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: productId,
        sku: sku,
        name: name,
        unit: 'chai',
        basePriceVnd: 10000,
        costVnd: Value(costVnd),
        active: Value(active),
        updatedAt: DateTime(2026),
      ),
    );
    await db.into(db.productStocks).insert(
      ProductStocksCompanion.insert(
        productId: productId,
        storeId: storeId,
        qty: qty,
        minQty: minQty,
        updatedAt: DateTime(2026),
      ),
    );
  }

  test('falls back to local aggregate on connection timeout', () async {
    await seedStock(
      productId: 'p1',
      sku: 'SKU-A',
      name: 'Product A',
      qty: '10',
      minQty: '5',
      costVnd: 2000,
    );
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/stock-on-hand',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/stock-on-hand'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    final report = await repository.fetch(storeId: 'store-1');

    expect(report.isOffline, isTrue);
    expect(report.storeId, 'store-1');
    expect(report.items, hasLength(1));
    expect(report.items.single.estimatedValueVnd, 20000);
    expect(report.totalEstimatedValueVnd, 20000);
  });

  test('rethrows unauthorized API errors', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/stock-on-hand',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/stock-on-hand'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/reports/stock-on-hand'),
          statusCode: 401,
        ),
      ),
    );

    expect(
      () => repository.fetch(storeId: 'store-1'),
      throwsA(isA<DioException>()),
    );
  });

  test('offline aggregate excludes inactive products and sorts belowMin first', () async {
    await seedStock(
      productId: 'p-low',
      sku: 'LOW',
      name: 'Below min',
      qty: '2',
      minQty: '5',
      costVnd: 1000,
    );
    await seedStock(
      productId: 'p-ok',
      sku: 'OK',
      name: 'Above min',
      qty: '10',
      minQty: '5',
      costVnd: 1000,
    );
    await seedStock(
      productId: 'p-off',
      sku: 'OFF',
      name: 'Inactive',
      qty: '99',
      active: false,
    );
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/stock-on-hand',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/stock-on-hand'),
        type: DioExceptionType.connectionError,
      ),
    );

    final report = await repository.fetch(storeId: 'store-1');

    expect(report.items, hasLength(2));
    expect(report.items[0].productId, 'p-low');
    expect(report.items[0].belowMin, isTrue);
    expect(report.items[1].productId, 'p-ok');
    expect(report.totalEstimatedValueVnd, 12000);
  });

  group('applyStockOnHandFilters', () {
    final items = [
      const StockOnHandItem(
        productId: 'p1',
        sku: 'AAA-1',
        name: 'Alpha',
        unit: 'chai',
        qty: 0,
        minQty: 5,
        costVnd: 1000,
        estimatedValueVnd: 0,
        belowMin: true,
      ),
      const StockOnHandItem(
        productId: 'p2',
        sku: 'BBB-2',
        name: 'Beta low',
        unit: 'goi',
        qty: 2,
        minQty: 5,
        costVnd: 1000,
        estimatedValueVnd: 2000,
        belowMin: true,
      ),
      const StockOnHandItem(
        productId: 'p3',
        sku: 'CCC-3',
        name: 'Gamma',
        unit: 'chai',
        qty: 10,
        minQty: 5,
        costVnd: 1000,
        estimatedValueVnd: 10000,
        belowMin: false,
      ),
    ];

    test('hides zero qty by default', () {
      final filtered = applyStockOnHandFilters(items);
      expect(filtered.map((i) => i.productId), ['p2', 'p3']);
    });

    test('showZero includes zero qty rows', () {
      final filtered = applyStockOnHandFilters(items, showZero: true);
      expect(filtered, hasLength(3));
    });

    test('belowMinOnly keeps only below-min rows', () {
      final filtered = applyStockOnHandFilters(items, belowMinOnly: true);
      expect(filtered.map((i) => i.productId), ['p2']);
    });

    test('search matches name or sku case-insensitively', () {
      final filtered = applyStockOnHandFilters(
        items,
        query: 'bbb',
        showZero: true,
      );
      expect(filtered.single.productId, 'p2');

      final byName = applyStockOnHandFilters(items, query: 'GAM');
      expect(byName.single.productId, 'p3');
    });
  });
}
