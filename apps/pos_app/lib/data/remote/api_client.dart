import 'package:dio/dio.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000',
);

class ApiClient {
  ApiClient({Dio? dio}) : dio = dio ?? Dio(BaseOptions(baseUrl: apiBaseUrl));

  final Dio dio;
}
