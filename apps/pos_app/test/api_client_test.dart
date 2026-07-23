import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/remote/api_client.dart';
import 'package:pos_app/features/auth/auth_repository.dart';

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
  test('AuthInterceptor attaches Bearer token when stored', () async {
    final storage = MemoryTokenStorage();
    await storage.write(key: accessTokenKey, value: 'jwt-token');

    String? capturedAuth;
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, tokenStorage: storage);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedAuth = options.headers['Authorization'] as String?;
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: {}),
          );
        },
      ),
    );

    await apiClient.dio.get('/stores');

    expect(capturedAuth, 'Bearer jwt-token');
  });

  test('AuthInterceptor omits Authorization when no token', () async {
    final storage = MemoryTokenStorage();

    String? capturedAuth;
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, tokenStorage: storage);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedAuth = options.headers['Authorization'] as String?;
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: {}),
          );
        },
      ),
    );

    await apiClient.dio.get('/stores');

    expect(capturedAuth, isNull);
  });
}
