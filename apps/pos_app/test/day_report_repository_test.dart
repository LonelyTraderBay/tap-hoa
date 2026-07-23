import 'package:dio/dio.dart';
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
