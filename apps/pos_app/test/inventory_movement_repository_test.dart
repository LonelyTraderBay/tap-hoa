import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/features/reports/inventory_movement_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late InventoryMovementRepository repository;

  setUp(() {
    dio = MockDio();
    repository = InventoryMovementRepository(dio: dio);
  });

  test('fetch parses report with per-docType breakdown', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/inventory-movement',
        queryParameters: {'storeId': 'store-1', 'periodYm': '2026-02'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reports/inventory-movement'),
        statusCode: 200,
        data: {
          'storeId': 'store-1',
          'periodYm': '2026-02',
          'items': [
            {
              'productId': 'p1',
              'sku': 'SKU-A',
              'name': 'San pham A',
              'unit': 'chai',
              'openingQty': 50,
              'inQty': 30,
              'outQty': 17,
              'closingQty': 63,
              'inByDocType': {'purchase': 30},
              'outByDocType': {'sale': 12, 'wastage': 5},
            },
            {
              'productId': 'p2',
              'sku': 'SKU-B',
              'name': 'San pham B',
              'unit': 'hop',
              'openingQty': 30,
              'inQty': 0,
              'outQty': 0,
              'closingQty': 30,
              'inByDocType': <String, dynamic>{},
              'outByDocType': <String, dynamic>{},
            },
          ],
        },
      ),
    );

    final report = await repository.fetch(
      storeId: 'store-1',
      periodYm: '2026-02',
    );

    expect(report.storeId, 'store-1');
    expect(report.periodYm, '2026-02');
    expect(report.items, hasLength(2));

    final a = report.items[0];
    expect(a.productId, 'p1');
    expect(a.openingQty, 50);
    expect(a.inQty, 30);
    expect(a.outQty, 17);
    expect(a.closingQty, 63);
    expect(a.inByDocType, {'purchase': 30.0});
    expect(a.outByDocType, {'sale': 12.0, 'wastage': 5.0});
    // Bất biến: closing == opening + in - out (khớp phía server).
    expect(a.closingQty, a.openingQty + a.inQty - a.outQty);

    final b = report.items[1];
    expect(b.openingQty, 30);
    expect(b.closingQty, 30);
    expect(b.inByDocType, isEmpty);
    expect(b.outByDocType, isEmpty);
  });

  test('fetch throws when response body is empty', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/inventory-movement',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reports/inventory-movement'),
        statusCode: 200,
      ),
    );

    expect(
      () => repository.fetch(storeId: 'store-1', periodYm: '2026-02'),
      throwsA(isA<StateError>()),
    );
  });

  test('fetch rethrows Dio errors (no offline fallback for this report)', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/inventory-movement',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reports/inventory-movement'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(
      () => repository.fetch(storeId: 'store-1', periodYm: '2026-02'),
      throwsA(isA<DioException>()),
    );
  });

  test('fetchCsv returns the csv string from the response body', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/inventory-movement.csv',
        queryParameters: {'storeId': 'store-1', 'periodYm': '2026-02'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/reports/inventory-movement.csv',
        ),
        statusCode: 200,
        data: {
          'storeId': 'store-1',
          'periodYm': '2026-02',
          'csv': 'productId,sku,name,unit,openingQty,inQty,outQty,closingQty',
        },
      ),
    );

    final csv = await repository.fetchCsv(
      storeId: 'store-1',
      periodYm: '2026-02',
    );

    expect(
      csv,
      'productId,sku,name,unit,openingQty,inQty,outQty,closingQty',
    );
  });

  test('fetchCsv returns empty string when body has no csv field', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/reports/inventory-movement.csv',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/reports/inventory-movement.csv',
        ),
        statusCode: 200,
      ),
    );

    final csv = await repository.fetchCsv(
      storeId: 'store-1',
      periodYm: '2026-02',
    );

    expect(csv, '');
  });
}
