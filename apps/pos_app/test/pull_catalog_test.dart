import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/data/sync/pull_catalog.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response<Map<String, dynamic>> {}

void main() {
  late AppDatabase db;
  late MockDio dio;
  late PullCatalog pullCatalog;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = MockDio();
    pullCatalog = PullCatalog(db: db, dio: dio);
  });

  tearDown(() => db.close());

  test('pullCatalog upserts products and stocks', () async {
    final response = MockResponse();
    when(() => response.data).thenReturn({
      'products': [
        {
          'id': 'prod-1',
          'sku': 'STING-330',
          'barcode': '8934588012345',
          'name': 'Sting do 330ml',
          'unit': 'chai',
          'isWeighted': false,
          'basePriceVnd': 10000,
          'costVnd': 7500,
          'active': true,
          'updatedAt': '2026-07-23T10:00:00.000Z',
        },
      ],
      'stocks': [
        {
          'productId': 'prod-1',
          'storeId': 'store-1',
          'qty': '100',
          'minQty': '10',
          'updatedAt': '2026-07-23T10:00:00.000Z',
        },
      ],
      'serverTime': '2026-07-23T10:05:00.000Z',
    });
    when(
      () => dio.get<Map<String, dynamic>>(
        '/sync/pull',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => response);

    await pullCatalog.pullCatalog('store-1');

    final products = await db.select(db.products).get();
    expect(products, hasLength(1));
    expect(products.single.sku, 'STING-330');
    expect(products.single.basePriceVnd, 10000);

    final stocks = await db.select(db.productStocks).get();
    expect(stocks.single.qty, '100');
    expect(stocks.single.storeId, 'store-1');

    final lastPullAt = await db.lastPullAt();
    expect(lastPullAt, DateTime.parse('2026-07-23T10:05:00.000Z'));
  });
}
