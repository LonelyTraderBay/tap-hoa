import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/reports/day_report_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AppDatabase db;
  late MockDio dio;
  late DayReportRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = MockDio();
    repository = DayReportRepository(dio: dio, db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSale({
    required String id,
    required DateTime clientCreatedAt,
    int totalVnd = 10000,
  }) async {
    await db.setMetaValue('currentStoreId', 'store-1');
    await db.into(db.salesLocal).insert(
      SalesLocalCompanion.insert(
        id: id,
        storeId: 'store-1',
        shiftId: 'shift-1',
        paymentMethod: 'cash',
        totalVnd: totalVnd,
        cashAmount: totalVnd,
        transferAmount: 0,
        debtAmount: 0,
        clientCreatedAt: clientCreatedAt,
      ),
    );
  }

  test('falls back to local sales on connection timeout', () async {
    await seedSale(
      id: 'sale-1',
      clientCreatedAt: DateTime.utc(2026, 7, 23, 10),
      totalVnd: 15000,
    );
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/day',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/day'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    final report = await repository.fetchDayReport(
      date: DateTime(2026, 7, 23),
      storeId: 'store-1',
    );

    expect(report.isOffline, isTrue);
    expect(report.totalRevenueVnd, 15000);
    expect(report.byStore, hasLength(1));
  });

  test('rethrows unauthorized API errors', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/day',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/day'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/reports/day'),
          statusCode: 401,
        ),
      ),
    );

    expect(
      () => repository.fetchDayReport(
        date: DateTime(2026, 7, 23),
        storeId: 'store-1',
      ),
      throwsA(isA<DioException>()),
    );
  });

  Future<void> seedProduct({
    required String id,
    required String sku,
    required String name,
    int costVnd = 0,
  }) async {
    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: id,
        sku: sku,
        name: name,
        unit: 'chai',
        basePriceVnd: 10000,
        costVnd: Value(costVnd),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> seedSaleWithLines({
    required String saleId,
    required DateTime clientCreatedAt,
    required List<({String lineId, String productId, String qty, int lineTotal})>
    lines,
  }) async {
    await db.setMetaValue('currentStoreId', 'store-1');
    final totalVnd = lines.fold<int>(0, (sum, line) => sum + line.lineTotal);
    await db.into(db.salesLocal).insert(
      SalesLocalCompanion.insert(
        id: saleId,
        storeId: 'store-1',
        shiftId: 'shift-1',
        paymentMethod: 'cash',
        totalVnd: totalVnd,
        cashAmount: totalVnd,
        transferAmount: 0,
        debtAmount: 0,
        clientCreatedAt: clientCreatedAt,
      ),
    );
    for (final line in lines) {
      await db.into(db.saleLinesLocal).insert(
        SaleLinesLocalCompanion.insert(
          id: line.lineId,
          saleId: saleId,
          productId: line.productId,
          qty: line.qty,
          unitPrice: line.lineTotal,
          lineTotal: line.lineTotal,
        ),
      );
    }
  }

  test('falls back to local top SKUs on connection timeout', () async {
    const productA = 'prod-a';
    const productB = 'prod-b';
    await seedProduct(
      id: productA,
      sku: 'SKU-A',
      name: 'Product A',
      costVnd: 5000,
    );
    await seedProduct(
      id: productB,
      sku: 'SKU-B',
      name: 'Product B',
      costVnd: 2000,
    );
    await seedSaleWithLines(
      saleId: 'sale-1',
      clientCreatedAt: DateTime.utc(2026, 7, 23, 10),
      lines: [
        (
          lineId: 'line-a1',
          productId: productA,
          qty: '3',
          lineTotal: 30000,
        ),
        (
          lineId: 'line-a2',
          productId: productA,
          qty: '2',
          lineTotal: 20000,
        ),
        (
          lineId: 'line-b1',
          productId: productB,
          qty: '3',
          lineTotal: 24000,
        ),
      ],
    );
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/top-skus',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/top-skus'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    final report = await repository.fetchTopSkus(
      date: DateTime(2026, 7, 23),
      storeId: 'store-1',
    );

    expect(report.isOffline, isTrue);
    expect(report.items, hasLength(2));
    expect(report.items[0].productId, productA);
    expect(report.items[0].qty, 5);
    expect(report.items[0].revenueVnd, 50000);
    expect(report.items[0].estimatedGrossVnd, 25000);
    expect(report.items[1].productId, productB);
    expect(report.items[1].qty, 3);
    expect(report.items[1].estimatedGrossVnd, 18000);
  });

  test('offline aggregation uses ICT day boundaries', () async {
    await seedSale(
      id: 'in-range',
      clientCreatedAt: DateTime.utc(2026, 7, 22, 18),
      totalVnd: 20000,
    );
    await seedSale(
      id: 'out-of-range',
      clientCreatedAt: DateTime.utc(2026, 7, 22, 16, 59),
      totalVnd: 5000,
    );
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/day',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/day'),
        type: DioExceptionType.connectionError,
      ),
    );

    final report = await repository.fetchDayReport(
      date: DateTime(2026, 7, 23),
      storeId: 'store-1',
    );

    expect(report.totalRevenueVnd, 20000);
    expect(report.byStore.single.orderCount, 1);
  });
}
