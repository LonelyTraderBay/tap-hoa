import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/local/database.dart';

const accessTokenKey = 'accessToken';

abstract interface class TokenStorage {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.role,
    required this.storeIds,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      storeIds: List<String>.from(json['storeIds'] as List),
    );
  }

  final String id;
  final String name;
  final String role;
  final List<String> storeIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'storeIds': storeIds,
  };
}

class AuthRepository {
  AuthRepository({
    required Dio dio,
    required TokenStorage secureStorage,
    required AppDatabase db,
  }) : _dio = dio,
       _secureStorage = secureStorage,
       _db = db;

  final Dio _dio;
  final TokenStorage _secureStorage;
  final AppDatabase _db;

  Future<AuthUser> login(String phone, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'phone': phone, 'password': password},
    );
    final data = response.data;
    if (data == null ||
        data['accessToken'] is! String ||
        data['user'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid login response');
    }

    final token = data['accessToken'] as String;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    await _secureStorage.write(key: accessTokenKey, value: token);
    await _db.transaction(() async {
      await _db.setMetaValue('currentUser', jsonEncode(user.toJson()));
      if (user.storeIds.isNotEmpty) {
        await _db.setMetaValue('currentStoreId', user.storeIds.first);
      }
    });
    return user;
  }
}
