import 'package:dio/dio.dart';

/// P2.3 — 1 dòng/sản phẩm của báo cáo nhập-xuất-tồn theo kỳ/điểm.
class InventoryMovementItem {
  const InventoryMovementItem({
    required this.productId,
    required this.sku,
    required this.name,
    required this.unit,
    required this.openingQty,
    required this.inQty,
    required this.outQty,
    required this.closingQty,
    required this.inByDocType,
    required this.outByDocType,
  });

  factory InventoryMovementItem.fromJson(Map<String, dynamic> json) {
    return InventoryMovementItem(
      productId: json['productId'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      openingQty: (json['openingQty'] as num).toDouble(),
      inQty: (json['inQty'] as num).toDouble(),
      outQty: (json['outQty'] as num).toDouble(),
      closingQty: (json['closingQty'] as num).toDouble(),
      inByDocType: _parseByDocType(json['inByDocType']),
      outByDocType: _parseByDocType(json['outByDocType']),
    );
  }

  static Map<String, double> _parseByDocType(dynamic raw) {
    final map = (raw as Map<String, dynamic>?) ?? const {};
    return map.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  final String productId;
  final String sku;
  final String name;
  final String unit;
  final double openingQty;
  final double inQty;
  final double outQty;
  final double closingQty;
  final Map<String, double> inByDocType;
  final Map<String, double> outByDocType;
}

class InventoryMovementReport {
  const InventoryMovementReport({
    required this.storeId,
    required this.periodYm,
    required this.items,
  });

  factory InventoryMovementReport.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(InventoryMovementItem.fromJson)
        .toList();
    return InventoryMovementReport(
      storeId: json['storeId'] as String,
      periodYm: json['periodYm'] as String,
      items: items,
    );
  }

  final String storeId;
  final String periodYm;
  final List<InventoryMovementItem> items;
}

/// Báo cáo kỳ (như `bank_recon_page.dart`/`ledger_page.dart`) — chỉ online,
/// không có fallback ngoại tuyến như `StockOnHandRepository` (đây là báo cáo
/// theo kỳ lịch sử phục vụ đối soát/kế toán, không phải quyết định tại quầy
/// lúc mất mạng như tồn hiện tại).
class InventoryMovementRepository {
  InventoryMovementRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<InventoryMovementReport> fetch({
    required String storeId,
    required String periodYm,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/inventory-movement',
      queryParameters: {'storeId': storeId, 'periodYm': periodYm},
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Empty inventory-movement response');
    }
    return InventoryMovementReport.fromJson(data);
  }

  Future<String> fetchCsv({
    required String storeId,
    required String periodYm,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/inventory-movement.csv',
      queryParameters: {'storeId': storeId, 'periodYm': periodYm},
    );
    return (response.data?['csv'] as String?) ?? '';
  }
}
