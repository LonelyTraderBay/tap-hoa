import 'package:dio/dio.dart';

import '../../features/auth/auth_repository.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000',
);

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.read(key: accessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class ApiClient {
  ApiClient({Dio? dio, required TokenStorage tokenStorage})
    : dio = dio ?? Dio(BaseOptions(baseUrl: apiBaseUrl)) {
    this.dio.interceptors.add(AuthInterceptor(tokenStorage));
  }

  final Dio dio;
}
