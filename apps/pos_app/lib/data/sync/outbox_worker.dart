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
  return (json[key] as List<dynamic>? ?? [])
      .map((id) => id as String)
      .toList();
}

List<RejectedSale> _rejectedItems(Map<String, dynamic> json, String key) {
  return [
    for (final item
        in (json[key] as List<dynamic>? ?? []).cast<Map<String, dynamic>>())
      RejectedSale(
        id: item['id'] as String,
        reason: item['reason'] as String,
      ),
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
    required this.acceptedStockTransferCreateIds,
    required this.acceptedStockTransferApproveIds,
    required this.acceptedStockTransferRejectIds,
    required this.acceptedStockTransferReceiveIds,
    required this.acceptedStocktakeIds,
    required this.acceptedPurchaseReceiptIds,
    required this.acceptedWastageIds,
    required this.rejected,
    required this.rejectedShifts,
    required this.rejectedDebtPayments,
    required this.rejectedCashVouchers,
    required this.rejectedProductUpserts,
    required this.rejectedStockTransferCreates,
    required this.rejectedStockTransferApproves,
    required this.rejectedStockTransferRejects,
    required this.rejectedStockTransferReceives,
    required this.rejectedStocktakes,
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
  final List<String> acceptedStockTransferCreateIds;
  final List<String> acceptedStockTransferApproveIds;
  final List<String> acceptedStockTransferRejectIds;
  final List<String> acceptedStockTransferReceiveIds;
  final List<String> acceptedStocktakeIds;
  final List<String> acceptedPurchaseReceiptIds;
  final List<String> acceptedWastageIds;
  final List<RejectedSale> rejected;
  final List<RejectedSale> rejectedShifts;
  final List<RejectedSale> rejectedDebtPayments;
  final List<RejectedSale> rejectedCashVouchers;
  final List<RejectedSale> rejectedProductUpserts;
  final List<RejectedSale> rejectedStockTransferCreates;
  final List<RejectedSale> rejectedStockTransferApproves;
  final List<RejectedSale> rejectedStockTransferRejects;
  final List<RejectedSale> rejectedStockTransferReceives;
  final List<RejectedSale> rejectedStocktakes;
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
      acceptedPurchaseReceiptIds: _stringIds(json, 'acceptedPurchaseReceiptIds'),
      acceptedWastageIds: _stringIds(json, 'acceptedWastageIds'),
      rejected: _rejectedItems(json, 'rejected'),
      rejectedShifts: _rejectedItems(json, 'rejectedShifts'),
      rejectedDebtPayments: _rejectedItems(json, 'rejectedDebtPayments'),
      rejectedCashVouchers: _rejectedItems(json, 'rejectedCashVouchers'),
      rejectedProductUpserts: _rejectedItems(json, 'rejectedProductUpserts'),
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
      rejectedPurchaseReceipts: _rejectedItems(json, 'rejectedPurchaseReceipts'),
      rejectedWastages: _rejectedItems(json, 'rejectedWastages'),
    );
  }
}

class RejectedSale {
  const RejectedSale({required this.id, required this.reason});

  final String id;
  final String reason;
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
    final stockTransferCreates = <Map<String, dynamic>>[];
    final stockTransferApproves = <Map<String, dynamic>>[];
    final stockTransferRejects = <Map<String, dynamic>>[];
    final stockTransferReceives = <Map<String, dynamic>>[];
    final stocktakes = <Map<String, dynamic>>[];
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
        stockTransferCreates.isEmpty &&
        stockTransferApproves.isEmpty &&
        stockTransferRejects.isEmpty &&
        stockTransferReceives.isEmpty &&
        stocktakes.isEmpty &&
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
          'stockTransferCreates': stockTransferCreates,
          'stockTransferApproves': stockTransferApproves,
          'stockTransferRejects': stockTransferRejects,
          'stockTransferReceives': stockTransferReceives,
          'stocktakes': stocktakes,
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
      await _db.markOutboxEntitiesDone('stocktake', result.acceptedStocktakeIds);
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
        result.rejectedPurchaseReceipts,
        entityType: 'purchase_receipt',
      );
      await markRejected(result.rejectedWastages, entityType: 'wastage');
    } on DioException {
      // stay pending; do not throw to UI
    }
  }

  Future<void> _applyClosedShiftSnapshots(
    List<ClosedShiftSnapshot> snapshots,
  ) async {
    for (final snapshot in snapshots) {
      await (_db.update(_db.shiftsLocal)..where((s) => s.id.equals(snapshot.id)))
          .write(
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
