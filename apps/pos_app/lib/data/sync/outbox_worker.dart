import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';

class ClosedShiftSnapshot {
  const ClosedShiftSnapshot({
    required this.id,
    required this.expectedCashVnd,
    required this.varianceVnd,
    required this.transferInShiftVnd,
    required this.closingCash,
    required this.closedAt,
    this.note,
  });

  final String id;
  final int expectedCashVnd;
  final int varianceVnd;
  final int transferInShiftVnd;
  final int closingCash;
  final DateTime closedAt;
  final String? note;

  factory ClosedShiftSnapshot.fromJson(Map<String, dynamic> json) {
    return ClosedShiftSnapshot(
      id: json['id'] as String,
      expectedCashVnd: json['expectedCashVnd'] as int,
      varianceVnd: json['varianceVnd'] as int,
      transferInShiftVnd: json['transferInShiftVnd'] as int,
      closingCash: json['closingCash'] as int,
      closedAt: DateTime.parse(json['closedAt'] as String),
      note: json['note'] as String?,
    );
  }
}

List<String> _stringIds(Map<String, dynamic> json, String key) {
  return (json[key] as List<dynamic>? ?? []).map((id) => id as String).toList();
}

List<RejectedSale> _rejectedItems(Map<String, dynamic> json, String key) {
  return [
    for (final item
        in (json[key] as List<dynamic>? ?? []).cast<Map<String, dynamic>>())
      RejectedSale(id: item['id'] as String, reason: item['reason'] as String),
  ];
}

class PushSyncResult {
  const PushSyncResult({
    required this.acceptedIds,
    required this.acceptedShiftIds,
    required this.acceptedShiftCloseIds,
    required this.closedShifts,
    required this.acceptedDebtPaymentIds,
    required this.acceptedCashVoucherIds,
    required this.acceptedCustomerUpsertIds,
    required this.acceptedProductUpsertIds,
    required this.acceptedProductGroupUpsertIds,
    required this.acceptedSaleReturnIds,
    required this.acceptedStockTransferCreateIds,
    required this.acceptedStockTransferApproveIds,
    required this.acceptedStockTransferRejectIds,
    required this.acceptedStockTransferReceiveIds,
    required this.acceptedStocktakeIds,
    required this.acceptedPurchaseOrderCreateIds,
    required this.acceptedPurchaseOrderOrderIds,
    required this.acceptedPurchaseOrderCloseIds,
    required this.acceptedPurchaseReceiptIds,
    required this.acceptedWastageIds,
    required this.rejected,
    required this.rejectedShifts,
    required this.rejectedDebtPayments,
    required this.rejectedCashVouchers,
    required this.rejectedProductUpserts,
    required this.rejectedProductGroupUpserts,
    required this.rejectedSaleReturns,
    required this.rejectedStockTransferCreates,
    required this.rejectedStockTransferApproves,
    required this.rejectedStockTransferRejects,
    required this.rejectedStockTransferReceives,
    required this.rejectedStocktakes,
    required this.rejectedPurchaseOrderCreates,
    required this.rejectedPurchaseOrderOrders,
    required this.rejectedPurchaseOrderCloses,
    required this.rejectedPurchaseReceipts,
    required this.rejectedWastages,
  });

  final List<String> acceptedIds;
  final List<String> acceptedShiftIds;
  final List<String> acceptedShiftCloseIds;
  final List<ClosedShiftSnapshot> closedShifts;
  final List<String> acceptedDebtPaymentIds;
  final List<String> acceptedCashVoucherIds;
  final List<String> acceptedCustomerUpsertIds;
  final List<String> acceptedProductUpsertIds;
  final List<String> acceptedProductGroupUpsertIds;
  final List<String> acceptedSaleReturnIds;
  final List<String> acceptedStockTransferCreateIds;
  final List<String> acceptedStockTransferApproveIds;
  final List<String> acceptedStockTransferRejectIds;
  final List<String> acceptedStockTransferReceiveIds;
  final List<String> acceptedStocktakeIds;
  final List<String> acceptedPurchaseOrderCreateIds;
  final List<String> acceptedPurchaseOrderOrderIds;
  final List<String> acceptedPurchaseOrderCloseIds;
  final List<String> acceptedPurchaseReceiptIds;
  final List<String> acceptedWastageIds;
  final List<RejectedSale> rejected;
  final List<RejectedSale> rejectedShifts;
  final List<RejectedSale> rejectedDebtPayments;
  final List<RejectedSale> rejectedCashVouchers;
  final List<RejectedSale> rejectedProductUpserts;
  final List<RejectedSale> rejectedProductGroupUpserts;
  final List<RejectedSale> rejectedSaleReturns;
  final List<RejectedSale> rejectedStockTransferCreates;
  final List<RejectedSale> rejectedStockTransferApproves;
  final List<RejectedSale> rejectedStockTransferRejects;
  final List<RejectedSale> rejectedStockTransferReceives;
  final List<RejectedSale> rejectedStocktakes;
  final List<RejectedSale> rejectedPurchaseOrderCreates;
  final List<RejectedSale> rejectedPurchaseOrderOrders;
  final List<RejectedSale> rejectedPurchaseOrderCloses;
  final List<RejectedSale> rejectedPurchaseReceipts;
  final List<RejectedSale> rejectedWastages;

  factory PushSyncResult.fromJson(Map<String, dynamic> json) {
    return PushSyncResult(
      acceptedIds: _stringIds(json, 'acceptedIds'),
      acceptedShiftIds: _stringIds(json, 'acceptedShiftIds'),
      acceptedShiftCloseIds: _stringIds(json, 'acceptedShiftCloseIds'),
      closedShifts: [
        for (final item
            in (json['closedShifts'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>())
          ClosedShiftSnapshot.fromJson(item),
      ],
      acceptedDebtPaymentIds: _stringIds(json, 'acceptedDebtPaymentIds'),
      acceptedCashVoucherIds: _stringIds(json, 'acceptedCashVoucherIds'),
      acceptedCustomerUpsertIds: _stringIds(json, 'acceptedCustomerUpsertIds'),
      acceptedProductUpsertIds: _stringIds(json, 'acceptedProductUpsertIds'),
      acceptedProductGroupUpsertIds: _stringIds(
        json,
        'acceptedProductGroupUpsertIds',
      ),
      acceptedSaleReturnIds: _stringIds(json, 'acceptedSaleReturnIds'),
      acceptedStockTransferCreateIds: _stringIds(
        json,
        'acceptedStockTransferCreateIds',
      ),
      acceptedStockTransferApproveIds: _stringIds(
        json,
        'acceptedStockTransferApproveIds',
      ),
      acceptedStockTransferRejectIds: _stringIds(
        json,
        'acceptedStockTransferRejectIds',
      ),
      acceptedStockTransferReceiveIds: _stringIds(
        json,
        'acceptedStockTransferReceiveIds',
      ),
      acceptedStocktakeIds: _stringIds(json, 'acceptedStocktakeIds'),
      acceptedPurchaseOrderCreateIds: _stringIds(
        json,
        'acceptedPurchaseOrderCreateIds',
      ),
      acceptedPurchaseOrderOrderIds: _stringIds(
        json,
        'acceptedPurchaseOrderOrderIds',
      ),
      acceptedPurchaseOrderCloseIds: _stringIds(
        json,
        'acceptedPurchaseOrderCloseIds',
      ),
      acceptedPurchaseReceiptIds: _stringIds(
        json,
        'acceptedPurchaseReceiptIds',
      ),
      acceptedWastageIds: _stringIds(json, 'acceptedWastageIds'),
      rejected: _rejectedItems(json, 'rejected'),
      rejectedShifts: _rejectedItems(json, 'rejectedShifts'),
      rejectedDebtPayments: _rejectedItems(json, 'rejectedDebtPayments'),
      rejectedCashVouchers: _rejectedItems(json, 'rejectedCashVouchers'),
      rejectedProductUpserts: _rejectedItems(json, 'rejectedProductUpserts'),
      rejectedProductGroupUpserts: _rejectedItems(
        json,
        'rejectedProductGroupUpserts',
      ),
      rejectedSaleReturns: _rejectedItems(json, 'rejectedSaleReturns'),
      rejectedStockTransferCreates: _rejectedItems(
        json,
        'rejectedStockTransferCreates',
      ),
      rejectedStockTransferApproves: _rejectedItems(
        json,
        'rejectedStockTransferApproves',
      ),
      rejectedStockTransferRejects: _rejectedItems(
        json,
        'rejectedStockTransferRejects',
      ),
      rejectedStockTransferReceives: _rejectedItems(
        json,
        'rejectedStockTransferReceives',
      ),
      rejectedStocktakes: _rejectedItems(json, 'rejectedStocktakes'),
      rejectedPurchaseOrderCreates: _rejectedItems(
        json,
        'rejectedPurchaseOrderCreates',
      ),
      rejectedPurchaseOrderOrders: _rejectedItems(
        json,
        'rejectedPurchaseOrderOrders',
      ),
      rejectedPurchaseOrderCloses: _rejectedItems(
        json,
        'rejectedPurchaseOrderCloses',
      ),
      rejectedPurchaseReceipts: _rejectedItems(
        json,
        'rejectedPurchaseReceipts',
      ),
      rejectedWastages: _rejectedItems(json, 'rejectedWastages'),
    );
  }
}

class RejectedSale {
  const RejectedSale({required this.id, required this.reason});

  final String id;
  final String reason;
}

// --- Backoff cho lỗi hạ tầng (P2.1) --------------------------------------
//
// Áp dụng khi `/sync/push` ném lỗi hạ tầng (mất mạng, server sập, timeout —
// bắt ở `on DioException` trong `tick()`), KHÔNG áp dụng khi server trả về
// 2xx nhưng từ chối một entry cụ thể vì lý do nghiệp vụ (`rejected*` — nhánh
// đó dùng `markOutboxError`, đã đúng từ trước, không đổi).
//
// Base = 15s, khớp đúng chu kỳ `Timer.periodic(const Duration(seconds: 15))`
// đẩy `tick()` trong `sync_scheduler.dart` (không import hằng số đó ở đây để
// tránh phụ thuộc ngược data/sync -> data/sync; 15s là "sự thật" duy nhất
// hiện sống ở `sync_scheduler.dart`, hằng số dưới đây chỉ NEO theo nó bằng
// giá trị, có ghi chú tại đây và tại đó). Chọn base = đúng chu kỳ tick hiện
// tại để lần backoff đầu tiên (retryCount=1, 15s) không khác gì hành vi cũ —
// chỉ từ lần lỗi hạ tầng THỨ HAI liên tiếp trở đi mới thực sự giãn ra.
const outboxBackoffBase = Duration(seconds: 15);

// Trần backoff. Chọn 8 phút — nằm giữa khoảng 5-10 phút hợp lý cho một hàng
// đợi outbox chứa chứng từ nghiệp vụ (bán hàng, thu nợ...): đủ dài để giảm
// mạnh tải lên server khi outage kéo dài (8 phút/lần so với 15s/lần cố định
// trước đây = giảm >97% số request trong 1 giờ mất mạng), đủ ngắn để khi
// mạng/server hồi phục, máy không "im lặng" quá lâu trước khi đồng bộ lại.
const outboxBackoffCap = Duration(minutes: 8);

// Số lần retry hạ tầng liên tiếp tối đa trước khi coi một entry là "hỏng
// bền" và chuyển sang `dead_letter` (loại khỏi vòng lặp tự động, cần người
// xem qua trong màn "Đồng bộ lỗi"). Với base=15s nhân đôi mỗi lần, trần 8
// phút (đạt trần đúng ở lần thử thứ 6: 15*2^5 = 480s = 8 phút), 10 lần retry
// cộng dồn ~ 15+30+60+120+240 + 480*5 = 465 + 2400 = 2865s (~48 phút) trước
// khi entry #10 hết hạn chờ và (nếu lỗi tiếp lần #11) mới thực sự
// dead-letter — tổng cộng dưới 1 giờ. Chọn 10 (giữa khoảng 8-15 hợp lý):
// thấp hơn sẽ dead-letter nhầm một đợt mất mạng vài-chục-phút (rất thường
// gặp với mạng 3G/4G ở cửa hàng nhỏ) dù nó sẽ tự khỏi; cao hơn sẽ để một
// entry hỏng THẬT (vd. server đổi API breaking, lỗi không bao giờ tự hết)
// nằm im nhiều giờ mà không ai biết cần vào sửa/báo.
const outboxMaxRetries = 10;

/// Backoff cấp số nhân: base * 2^(retryCount-1), trần ở [outboxBackoffCap].
/// [retryCount] là số lần lỗi hạ tầng liên tiếp SAU KHI đã tăng (1-based —
/// lần lỗi đầu tiên truyền vào đây là 1, không phải 0).
Duration outboxBackoffDuration(int retryCount) {
  // Chặn exponent để tránh shift-overflow lý thuyết nếu retryCount bất
  // thường lớn (không nên xảy ra trong thực tế vì entry đã dead-letter và
  // rời khỏi `pendingOutbox()` trước khi retryCount vượt [outboxMaxRetries]
  // rất nhiều, nhưng hàm này vẫn nên an toàn độc lập với caller).
  final exponent = (retryCount - 1).clamp(0, 20);
  final scaled = outboxBackoffBase * (1 << exponent);
  return scaled > outboxBackoffCap ? outboxBackoffCap : scaled;
}

class OutboxWorker {
  OutboxWorker({required AppDatabase db, required Dio dio})
    : _db = db,
      _dio = dio;

  final AppDatabase _db;
  final Dio _dio;
  final _uuid = const Uuid();

  Future<void> tick() async {
    final pending = await _db.pendingOutbox(limit: 50);
    final sales = <Map<String, dynamic>>[];
    final shiftOpens = <Map<String, dynamic>>[];
    final shiftCloses = <Map<String, dynamic>>[];
    final debtPayments = <Map<String, dynamic>>[];
    final cashVouchers = <Map<String, dynamic>>[];
    final customerUpserts = <Map<String, dynamic>>[];
    final productUpserts = <Map<String, dynamic>>[];
    final productGroupUpserts = <Map<String, dynamic>>[];
    final saleReturns = <Map<String, dynamic>>[];
    final stockTransferCreates = <Map<String, dynamic>>[];
    final stockTransferApproves = <Map<String, dynamic>>[];
    final stockTransferRejects = <Map<String, dynamic>>[];
    final stockTransferReceives = <Map<String, dynamic>>[];
    final stocktakes = <Map<String, dynamic>>[];
    final purchaseOrderCreates = <Map<String, dynamic>>[];
    final purchaseOrderOrders = <Map<String, dynamic>>[];
    final purchaseOrderCloses = <Map<String, dynamic>>[];
    final purchaseReceipts = <Map<String, dynamic>>[];
    final wastages = <Map<String, dynamic>>[];

    for (final entry in pending) {
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      switch (entry.entityType) {
        case 'shift_open':
          shiftOpens.add(payload);
        case 'sale':
          sales.add(payload);
        case 'shift_close':
          shiftCloses.add(payload);
        case 'debt_payment':
          debtPayments.add(payload);
        case 'cash_voucher':
          cashVouchers.add(payload);
        case 'customer_upsert':
          customerUpserts.add(payload);
        case 'product_upsert':
          productUpserts.add(payload);
        case 'product_group_upsert':
          productGroupUpserts.add(payload);
        case 'sale_return':
          saleReturns.add(payload);
        case 'stock_transfer_create':
          stockTransferCreates.add(payload);
        case 'stock_transfer_approve':
          stockTransferApproves.add(payload);
        case 'stock_transfer_reject':
          stockTransferRejects.add(payload);
        case 'stock_transfer_receive':
          stockTransferReceives.add(payload);
        case 'stocktake':
          stocktakes.add(payload);
        case 'purchase_order_create':
          purchaseOrderCreates.add(payload);
        case 'purchase_order_order':
          purchaseOrderOrders.add(payload);
        case 'purchase_order_close':
          purchaseOrderCloses.add(payload);
        case 'purchase_receipt':
          purchaseReceipts.add(payload);
        case 'wastage':
          wastages.add(payload);
      }
    }
    if (shiftOpens.isEmpty &&
        sales.isEmpty &&
        shiftCloses.isEmpty &&
        debtPayments.isEmpty &&
        cashVouchers.isEmpty &&
        customerUpserts.isEmpty &&
        productUpserts.isEmpty &&
        productGroupUpserts.isEmpty &&
        saleReturns.isEmpty &&
        stockTransferCreates.isEmpty &&
        stockTransferApproves.isEmpty &&
        stockTransferRejects.isEmpty &&
        stockTransferReceives.isEmpty &&
        stocktakes.isEmpty &&
        purchaseOrderCreates.isEmpty &&
        purchaseOrderOrders.isEmpty &&
        purchaseOrderCloses.isEmpty &&
        purchaseReceipts.isEmpty &&
        wastages.isEmpty) {
      return;
    }

    try {
      final deviceId = await _deviceId();
      final response = await _dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: {
          'deviceId': deviceId,
          'shiftOpens': shiftOpens,
          'sales': sales,
          'cashVouchers': cashVouchers,
          'debtPayments': debtPayments,
          'shiftCloses': shiftCloses,
          'customerUpserts': customerUpserts,
          'productUpserts': productUpserts,
          'productGroupUpserts': productGroupUpserts,
          'saleReturns': saleReturns,
          'stockTransferCreates': stockTransferCreates,
          'stockTransferApproves': stockTransferApproves,
          'stockTransferRejects': stockTransferRejects,
          'stockTransferReceives': stockTransferReceives,
          'stocktakes': stocktakes,
          'purchaseOrderCreates': purchaseOrderCreates,
          'purchaseOrderOrders': purchaseOrderOrders,
          'purchaseOrderCloses': purchaseOrderCloses,
          'purchaseReceipts': purchaseReceipts,
          'wastages': wastages,
        },
      );
      final data = response.data;
      if (data == null) {
        return;
      }
      final result = PushSyncResult.fromJson(data);
      await _db.markOutboxEntitiesDone('shift_open', result.acceptedShiftIds);
      await _db.markOutboxDone(result.acceptedIds);
      await _db.markOutboxEntitiesDone(
        'shift_close',
        result.acceptedShiftCloseIds,
      );
      await _applyClosedShiftSnapshots(result.closedShifts);
      await _db.markOutboxEntitiesDone(
        'debt_payment',
        result.acceptedDebtPaymentIds,
      );
      await _db.markOutboxEntitiesDone(
        'cash_voucher',
        result.acceptedCashVoucherIds,
      );
      await _db.markOutboxEntitiesDone(
        'customer_upsert',
        result.acceptedCustomerUpsertIds,
      );
      await _db.markOutboxEntitiesDone(
        'product_upsert',
        result.acceptedProductUpsertIds,
      );
      await _db.markOutboxEntitiesDone(
        'product_group_upsert',
        result.acceptedProductGroupUpsertIds,
      );
      await _db.markOutboxEntitiesDone(
        'sale_return',
        result.acceptedSaleReturnIds,
      );
      await _db.markOutboxEntitiesDone(
        'stock_transfer_create',
        result.acceptedStockTransferCreateIds,
      );
      await _db.markOutboxEntitiesDone(
        'stock_transfer_approve',
        result.acceptedStockTransferApproveIds,
      );
      await _db.markOutboxEntitiesDone(
        'stock_transfer_reject',
        result.acceptedStockTransferRejectIds,
      );
      await _db.markOutboxEntitiesDone(
        'stock_transfer_receive',
        result.acceptedStockTransferReceiveIds,
      );
      await _db.markOutboxEntitiesDone(
        'stocktake',
        result.acceptedStocktakeIds,
      );
      await _db.markOutboxEntitiesDone(
        'purchase_order_create',
        result.acceptedPurchaseOrderCreateIds,
      );
      await _db.markOutboxEntitiesDone(
        'purchase_order_order',
        result.acceptedPurchaseOrderOrderIds,
      );
      await _db.markOutboxEntitiesDone(
        'purchase_order_close',
        result.acceptedPurchaseOrderCloseIds,
      );
      await _db.markOutboxEntitiesDone(
        'purchase_receipt',
        result.acceptedPurchaseReceiptIds,
      );
      await _db.markOutboxEntitiesDone('wastage', result.acceptedWastageIds);

      Future<void> markRejected(
        List<RejectedSale> items, {
        required String entityType,
      }) async {
        for (final rejected in items) {
          await _db.markOutboxError(
            rejected.id,
            rejected.reason,
            entityType: entityType,
          );
        }
      }

      for (final rejected in result.rejected) {
        await _db.markOutboxError(
          rejected.id,
          rejected.reason,
          entityType: 'sale',
        );
      }
      for (final rejected in result.rejectedShifts) {
        await _db.markOutboxError(rejected.id, rejected.reason);
      }
      // Thu nợ bị server từ chối là từ chối VĨNH VIỄN (nghiệp vụ), không phải
      // lỗi tạm thời: server chỉ đưa entry vào `rejectedDebtPayments` cho
      // payment_exceeds_balance / customer_not_found / invalid_payment. Mọi lỗi
      // hạ tầng đều ném ra ngoài và tới đây dưới dạng DioException (bắt ở
      // catch bên dưới, giữ pending). Vì local đã trừ nợ ngay khi thu nên phải
      // hoàn tác trước khi đánh dấu entry lỗi.
      for (final rejected in result.rejectedDebtPayments) {
        await _db.revertLocalDebtPayment(rejected.id);
      }
      await markRejected(
        result.rejectedDebtPayments,
        entityType: 'debt_payment',
      );
      await markRejected(
        result.rejectedCashVouchers,
        entityType: 'cash_voucher',
      );
      await markRejected(
        result.rejectedProductUpserts,
        entityType: 'product_upsert',
      );
      await markRejected(
        result.rejectedProductGroupUpserts,
        entityType: 'product_group_upsert',
      );
      await markRejected(result.rejectedSaleReturns, entityType: 'sale_return');
      await markRejected(
        result.rejectedStockTransferCreates,
        entityType: 'stock_transfer_create',
      );
      await markRejected(
        result.rejectedStockTransferApproves,
        entityType: 'stock_transfer_approve',
      );
      await markRejected(
        result.rejectedStockTransferRejects,
        entityType: 'stock_transfer_reject',
      );
      await markRejected(
        result.rejectedStockTransferReceives,
        entityType: 'stock_transfer_receive',
      );
      await markRejected(result.rejectedStocktakes, entityType: 'stocktake');
      await markRejected(
        result.rejectedPurchaseOrderCreates,
        entityType: 'purchase_order_create',
      );
      await markRejected(
        result.rejectedPurchaseOrderOrders,
        entityType: 'purchase_order_order',
      );
      await markRejected(
        result.rejectedPurchaseOrderCloses,
        entityType: 'purchase_order_close',
      );
      await markRejected(
        result.rejectedPurchaseReceipts,
        entityType: 'purchase_receipt',
      );
      await markRejected(result.rejectedWastages, entityType: 'wastage');
    } on DioException {
      // Lỗi hạ tầng (mất mạng, server sập, timeout) — KHÔNG throw ra UI
      // (giữ hành vi cũ), nhưng giờ backoff thay vì để `pending` mãi mãi ở
      // trạng thái "sẵn sàng retry ngay" (tick 15s sau lại gửi y hệt batch
      // này, dội server vô thời hạn nếu outage kéo dài). `pending` ở đây
      // vẫn đúng là batch VỪA gửi thất bại — không có gì khác ghi/đọc xen
      // vào giữa lúc fetch nó ở đầu `tick()` và catch này trong cùng một
      // lượt gọi đồng bộ.
      await _db.recordOutboxInfraFailure(
        pending,
        backoffFor: outboxBackoffDuration,
        maxRetries: outboxMaxRetries,
      );
    }
  }

  Future<void> _applyClosedShiftSnapshots(
    List<ClosedShiftSnapshot> snapshots,
  ) async {
    for (final snapshot in snapshots) {
      await (_db.update(
        _db.shiftsLocal,
      )..where((s) => s.id.equals(snapshot.id))).write(
        ShiftsLocalCompanion(
          closedAt: Value(snapshot.closedAt),
          closingCash: Value(snapshot.closingCash),
          note: Value(snapshot.note),
          expectedCashVnd: Value(snapshot.expectedCashVnd),
          varianceVnd: Value(snapshot.varianceVnd),
          transferInShiftVnd: Value(snapshot.transferInShiftVnd),
        ),
      );
    }
  }

  Future<String> _deviceId() async {
    final existing = await _db.metaValue('deviceId');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final id = _uuid.v4();
    await _db.setMetaValue('deviceId', id);
    return id;
  }
}
