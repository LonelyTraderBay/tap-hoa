import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/auth/auth_repository.dart';

class MockDio extends Mock implements Dio {}

class MemoryTokenStorage implements TokenStorage {
  final _values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

void main() {
  late MockDio dio;
  late MemoryTokenStorage storage;
  late AppDatabase db;

  setUp(() {
    dio = MockDio();
    storage = MemoryTokenStorage();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('login stores access token and current user session', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: {
          'accessToken': 'jwt-token',
          'user': {
            'id': 'user-1',
            'name': 'Owner',
            'role': 'owner',
            'storeIds': ['store-1'],
            'canLedger': false,
            'canEinvoice': false,
          },
        },
      ),
    );

    final repository = AuthRepository(dio: dio, secureStorage: storage, db: db);
    final user = await repository.login('0900000001', '123456');

    expect(user.role, 'owner');
    expect(user.canLedger, isTrue);
    expect(user.canEinvoice, isTrue);
    expect(await storage.read(key: accessTokenKey), 'jwt-token');
    expect(await db.metaValue('currentUser'), contains('"canLedger":true'));
    expect(await db.metaValue('currentUser'), contains('"canEinvoice":true'));
    expect(await db.metaValue('currentUser'), contains('"id":"user-1"'));
    expect(await db.metaValue('currentStoreId'), 'store-1');
    verify(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'phone': '0900000001', 'password': '123456'},
      ),
    ).called(1);
  });

  test('login stores configurable manager permission flags', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: {
          'accessToken': 'jwt-token',
          'user': {
            'id': 'user-2',
            'name': 'Manager',
            'role': 'store_manager',
            'storeIds': ['store-1'],
            'canLedger': true,
            'canEinvoice': false,
          },
        },
      ),
    );

    final repository = AuthRepository(dio: dio, secureStorage: storage, db: db);
    final user = await repository.login('0900000002', '123456');

    expect(user.canLedger, isTrue);
    expect(user.canEinvoice, isFalse);
    expect(await db.metaValue('currentUser'), contains('"canLedger":true'));
    expect(await db.metaValue('currentUser'), contains('"canEinvoice":false'));
  });

  test('cashier cannot enable ledger or e-invoice via raw flags', () {
    final user = AuthUser.fromJson({
      'id': 'user-3',
      'name': 'Cashier',
      'role': 'cashier',
      'storeIds': ['store-1'],
      'canLedger': true,
      'canEinvoice': true,
    });

    expect(user.canLedger, isFalse);
    expect(user.canEinvoice, isFalse);
  });
}
