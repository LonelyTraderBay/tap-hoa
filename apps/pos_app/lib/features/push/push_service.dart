import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/local/database.dart';
import '../../firebase_options.dart';
import '../reports/ict_date.dart';

/// Registers FCM token when Firebase is configured; otherwise no-ops.
class PushService {
  PushService({required AppDatabase db, required Dio dio})
      : _db = db,
        _dio = dio;

  final AppDatabase _db;
  final Dio _dio;

  static bool _firebaseReady = false;

  Future<void> ensureFirebase() async {
    if (_firebaseReady) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseReady = true;
    } catch (e) {
      debugPrint('PushService: Firebase init skipped: $e');
    }
  }

  Future<void> registerAfterLogin() async {
    try {
      final deviceId = await _db.metaValue('deviceId');
      if (deviceId == null || deviceId.isEmpty) return;

      await ensureFirebase();
      if (_firebaseReady) {
        try {
          final messaging = FirebaseMessaging.instance;
          await messaging.requestPermission();
          final token = await messaging.getToken();
          if (token != null && token.isNotEmpty) {
            await _db.setMetaValue('fcmToken', token);
          }
        } catch (e) {
          debugPrint('PushService: getToken failed: $e');
        }
      }

      final token = await _db.metaValue('fcmToken');
      if (token == null || token.isEmpty) {
        debugPrint('PushService: no fcmToken in meta — skip register');
        return;
      }

      await _dio.post<void>(
        '/devices/push-token',
        data: {
          'deviceId': deviceId,
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
    } catch (e) {
      debugPrint('PushService register failed: $e');
    }
  }

  /// After pull: notify for SKUs under minQty (deduped per ICT day).
  Future<void> checkLowStock(String storeId) async {
    try {
      final stocks = await (_db.select(_db.productStocks)
            ..where((t) => t.storeId.equals(storeId)))
          .get();
      final ict = formatIctDate(ictToday());
      for (final stock in stocks) {
        final qty = Decimal.tryParse(stock.qty) ?? Decimal.zero;
        final minQty = Decimal.tryParse(stock.minQty) ?? Decimal.zero;
        if (qty >= minQty) continue;
        final key = 'lowStockNotified:${stock.productId}:$ict';
        final already = await _db.metaValue(key);
        if (already == '1') continue;

        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(stock.productId)))
            .getSingleOrNull();
        final name = product?.name ?? stock.productId;

        try {
          await _dio.post<void>(
            '/devices/low-stock-alert',
            data: {
              'storeId': storeId,
              'productId': stock.productId,
              'productName': name,
              'qty': stock.qty,
            },
          );
        } catch (e) {
          debugPrint('low-stock-alert failed: $e');
        }
        await _db.setMetaValue(key, '1');
      }
    } catch (e) {
      debugPrint('PushService.checkLowStock failed: $e');
    }
  }
}
