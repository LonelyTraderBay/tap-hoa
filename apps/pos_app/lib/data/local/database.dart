import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

const lastBackupAtMetaKey = 'lastBackupAt';

/// Reason code ghi vào `lastError` khi một outbox entry bị chuyển sang
/// `status = 'dead_letter'` (hết lượt retry hạ tầng, xem
/// `recordOutboxInfraFailure`). Cố tình dùng reason CODE (snake_case) thay
/// vì viết thẳng câu tiếng Việt — đúng convention hiện có của cột này (so
/// với `'insufficient_stock'`, `'sku_conflict'`...), để
/// `outbox_reason_labels.dart::labelOutboxReason` là nơi DUY NHẤT quyết
/// định câu hiển thị cho người dùng (giữ nguyên tắc "lastError chứa mã lỗi
/// ổn định, UI tự dịch", không rò rỉ câu tiếng Việt hoặc message
/// DioException thô vào tầng dữ liệu).
const outboxSyncRetryExhaustedReason = 'sync_retry_exhausted';

@DriftDatabase(
  tables: [
    Products,
    ProductGroups,
    ProductComboComponents,
    ProductStocks,
    OutboxEntries,
    SalesLocal,
    SaleLinesLocal,
    SaleReturnsLocal,
    SaleReturnLinesLocal,
    ShiftsLocal,
    StoresLocal,
    MetaLocal,
    CustomersLocal,
    DebtLedgerLocal,
    CashCategoriesLocal,
    CashVouchersLocal,
    StockTransfersLocal,
    StockTransferLinesLocal,
    StocktakesLocal,
    StocktakeLinesLocal,
    PurchaseOrdersLocal,
    PurchaseOrderLinesLocal,
    PurchaseReceiptsLocal,
    PurchaseReceiptLinesLocal,
    WastageVouchersLocal,
    WastageVoucherLinesLocal,
    StockMovementsLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(customersLocal);
      }
      if (from < 3) {
        await migrator.addColumn(customersLocal, customersLocal.creditLimitVnd);
        await migrator.createTable(debtLedgerLocal);
      }
      if (from < 4) {
        await migrator.createTable(cashCategoriesLocal);
        await migrator.createTable(cashVouchersLocal);
        await migrator.addColumn(shiftsLocal, shiftsLocal.expectedCashVnd);
        await migrator.addColumn(shiftsLocal, shiftsLocal.varianceVnd);
        await migrator.addColumn(shiftsLocal, shiftsLocal.transferInShiftVnd);
      }
      if (from < 5) {
        await migrator.createTable(stockTransfersLocal);
        await migrator.createTable(stockTransferLinesLocal);
        await migrator.createTable(stocktakesLocal);
        await migrator.createTable(stocktakeLinesLocal);
        await migrator.createTable(purchaseReceiptsLocal);
        await migrator.createTable(purchaseReceiptLinesLocal);
        await migrator.createTable(wastageVouchersLocal);
        await migrator.createTable(wastageVoucherLinesLocal);
        await migrator.createTable(stockMovementsLocal);
      }
      if (from < 6) {
        await migrator.createTable(productGroups);
        await migrator.createTable(productComboComponents);
        await migrator.createTable(saleReturnsLocal);
        await migrator.createTable(saleReturnLinesLocal);
        await migrator.addColumn(products, products.sellUnit);
        await migrator.addColumn(products, products.packSize);
        await migrator.addColumn(products, products.kind);
        await migrator.addColumn(products, products.groupId);
        await migrator.addColumn(storesLocal, storesLocal.debtOverdueDays);
      }
      if (from < 7) {
        await migrator.addColumn(productStocks, productStocks.avgCostVnd);
        await migrator.addColumn(saleLinesLocal, saleLinesLocal.unitCostVnd);
      }
      if (from < 8) {
        await migrator.addColumn(saleLinesLocal, saleLinesLocal.discountVnd);
      }
      if (from < 9) {
        await migrator.createTable(purchaseOrdersLocal);
        await migrator.createTable(purchaseOrderLinesLocal);
        await migrator.addColumn(
          purchaseReceiptsLocal,
          purchaseReceiptsLocal.supplierId,
        );
        await migrator.addColumn(
          purchaseReceiptsLocal,
          purchaseReceiptsLocal.purchaseOrderId,
        );
      }
      if (from < 10) {
        await migrator.addColumn(
          storesLocal,
          storesLocal.largeDebtThresholdVnd,
        );
      }
      if (from < 11) {
        await migrator.addColumn(
          storesLocal,
          storesLocal.allowNegativeStock,
        );
      }
      if (from < 12) {
        await migrator.addColumn(outboxEntries, outboxEntries.retryCount);
        await migrator.addColumn(outboxEntries, outboxEntries.nextRetryAt);
        // `addColumn` chỉ thêm cột (ALTER TABLE ADD COLUMN) — nó KHÔNG cập
        // nhật CHECK constraint hiện có trên cột `status` (SQLite không hỗ
        // trợ sửa CHECK bằng ALTER trực tiếp). Nếu dừng ở 2 dòng addColumn
        // trên, máy đã cài đặt từ trước (upgrade từ schema < 12) vẫn giữ
        // CHECK constraint cũ 3 giá trị — UPDATE status='dead_letter' sau
        // này sẽ ném SqliteException CHECK constraint failed chỉ trên NHỮNG
        // MÁY ĐÃ CÀI TRƯỚC ĐÓ (máy cài mới qua `onCreate`/`createAll()` thì
        // không sao vì đọc thẳng schema hiện tại trong tables.dart). Gọi
        // `alterTable` (không kèm `newColumns`, vì 2 cột trên đã tồn tại
        // sau 2 dòng addColumn ngay phía trên) để recreate bảng theo đúng
        // 12-bước sqlite.org/lang_altertable.html#otheralter mà package
        // drift đã cài sẵn — giữ nguyên toàn bộ dữ liệu, chỉ đổi CHECK
        // constraint sang bản mới (khớp `OutboxEntries` trong tables.dart).
        await migrator.alterTable(TableMigration(outboxEntries));
      }
      if (from < 13) {
        // P2.2: shiftId của CashVouchersLocal chuyển NOT NULL -> nullable
        // (phiếu bank-recon server-side không gắn ca, kéo về qua pull). Như
        // trường hợp `outboxEntries`/CHECK constraint ở migration 12,
        // SQLite không hỗ trợ sửa nullability bằng ALTER trực tiếp — dùng
        // `alterTable` để recreate bảng theo đúng schema `tables.dart`
        // hiện tại (giữ nguyên dữ liệu, chỉ đổi ràng buộc NOT NULL).
        await migrator.alterTable(TableMigration(cashVouchersLocal));
      }
    },
  );

  Future<String?> metaValue(String key) async {
    final row = await (select(
      metaLocal,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMetaValue(String key, String value) {
    return into(metaLocal).insertOnConflictUpdate(
      MetaLocalCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  String _lastPullAtKey(String storeId) => 'lastPullAt:$storeId';

  Future<DateTime?> lastPullAt(String storeId) async {
    final value = await metaValue(_lastPullAtKey(storeId));
    if (value == null) {
      return null;
    }
    return DateTime.parse(value);
  }

  Future<void> setLastPullAt(String storeId, DateTime at) {
    return setMetaValue(_lastPullAtKey(storeId), at.toUtc().toIso8601String());
  }

  Future<DateTime?> lastBackupAt() async {
    final value = await metaValue(lastBackupAtMetaKey);
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> setLastBackupAt(DateTime at) {
    return setMetaValue(lastBackupAtMetaKey, at.toUtc().toIso8601String());
  }

  Future<void> upsertCashCategory(Map<String, dynamic> category) {
    return into(cashCategoriesLocal).insertOnConflictUpdate(
      CashCategoriesLocalCompanion.insert(
        id: category['id'] as String,
        code: category['code'] as String,
        name: category['name'] as String,
        direction: category['direction'] as String,
        sortOrder: Value(category['sortOrder'] as int? ?? 0),
      ),
    );
  }

  Future<void> upsertCashVoucher(Map<String, dynamic> voucher) {
    return into(cashVouchersLocal).insertOnConflictUpdate(
      CashVouchersLocalCompanion.insert(
        id: voucher['id'] as String,
        storeId: voucher['storeId'] as String,
        // Null cho phiếu tạo từ đối chiếu ngân hàng server-side (P2.2) — xem
        // ghi chú nullable trên cột này trong tables.dart.
        shiftId: Value(voucher['shiftId'] as String?),
        categoryId: voucher['categoryId'] as String,
        direction: voucher['direction'] as String,
        channel: voucher['channel'] as String,
        amountVnd: voucher['amountVnd'] as int,
        note: Value(voucher['note'] as String?),
        recordedById: voucher['recordedById'] as String,
        clientCreatedAt: DateTime.parse(voucher['clientCreatedAt'] as String),
        updatedAt: DateTime.parse(voucher['updatedAt'] as String),
      ),
    );
  }

  Future<void> upsertInventoryFromPull({
    required List<Map<String, dynamic>> stockTransfers,
    required List<Map<String, dynamic>> stocktakes,
    required List<Map<String, dynamic>> purchaseOrders,
    required List<Map<String, dynamic>> purchaseReceipts,
    required List<Map<String, dynamic>> wastageVouchers,
    required List<Map<String, dynamic>> stockMovements,
  }) async {
    await transaction(() async {
      for (final t in stockTransfers) {
        await into(stockTransfersLocal).insertOnConflictUpdate(
          StockTransfersLocalCompanion.insert(
            id: t['id'] as String,
            fromStoreId: t['fromStoreId'] as String,
            toStoreId: t['toStoreId'] as String,
            status: t['status'] as String,
            note: Value(t['note'] as String?),
            createdById: t['createdById'] as String,
            approvedById: Value(t['approvedById'] as String?),
            receivedById: Value(t['receivedById'] as String?),
            clientCreatedAt: DateTime.parse(t['clientCreatedAt'] as String),
            approvedAt: Value(
              t['approvedAt'] != null
                  ? DateTime.parse(t['approvedAt'] as String)
                  : null,
            ),
            receivedAt: Value(
              t['receivedAt'] != null
                  ? DateTime.parse(t['receivedAt'] as String)
                  : null,
            ),
            updatedAt: DateTime.parse(t['updatedAt'] as String),
          ),
        );
        for (final line
            in (t['lines'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>()) {
          await into(stockTransferLinesLocal).insertOnConflictUpdate(
            StockTransferLinesLocalCompanion.insert(
              id: line['id'] as String,
              transferId: t['id'] as String,
              productId: line['productId'] as String,
              qty: line['qty'] as String,
            ),
          );
        }
      }
      for (final s in stocktakes) {
        await into(stocktakesLocal).insertOnConflictUpdate(
          StocktakesLocalCompanion.insert(
            id: s['id'] as String,
            storeId: s['storeId'] as String,
            note: Value(s['note'] as String?),
            recordedById: s['recordedById'] as String,
            clientCreatedAt: DateTime.parse(s['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(s['updatedAt'] as String),
          ),
        );
        for (final line
            in (s['lines'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>()) {
          await into(stocktakeLinesLocal).insertOnConflictUpdate(
            StocktakeLinesLocalCompanion.insert(
              id: line['id'] as String,
              stocktakeId: s['id'] as String,
              productId: line['productId'] as String,
              systemQty: line['systemQty'] as String,
              countedQty: line['countedQty'] as String,
              varianceQty: line['varianceQty'] as String,
              reason: line['reason'] as String,
              reasonNote: Value(line['reasonNote'] as String?),
            ),
          );
        }
      }
      for (final o in purchaseOrders) {
        await into(purchaseOrdersLocal).insertOnConflictUpdate(
          PurchaseOrdersLocalCompanion.insert(
            id: o['id'] as String,
            storeId: o['storeId'] as String,
            supplierName: o['supplierName'] as String,
            supplierPhone: Value(o['supplierPhone'] as String?),
            supplierId: Value(o['supplierId'] as String?),
            status: o['status'] as String,
            note: Value(o['note'] as String?),
            createdById: o['createdById'] as String,
            clientCreatedAt: DateTime.parse(o['clientCreatedAt'] as String),
            orderedAt: Value(
              o['orderedAt'] != null
                  ? DateTime.parse(o['orderedAt'] as String)
                  : null,
            ),
            closedAt: Value(
              o['closedAt'] != null
                  ? DateTime.parse(o['closedAt'] as String)
                  : null,
            ),
            updatedAt: DateTime.parse(o['updatedAt'] as String),
          ),
        );
        for (final line
            in (o['lines'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>()) {
          await into(purchaseOrderLinesLocal).insertOnConflictUpdate(
            PurchaseOrderLinesLocalCompanion.insert(
              id: line['id'] as String,
              purchaseOrderId: o['id'] as String,
              productId: line['productId'] as String,
              qty: line['qty'] as String,
              receivedQty: Value(line['receivedQty'] as String? ?? '0'),
              unitCostVnd: Value(line['unitCostVnd'] as int?),
            ),
          );
        }
      }
      for (final r in purchaseReceipts) {
        await into(purchaseReceiptsLocal).insertOnConflictUpdate(
          PurchaseReceiptsLocalCompanion.insert(
            id: r['id'] as String,
            storeId: r['storeId'] as String,
            supplierName: r['supplierName'] as String,
            supplierPhone: Value(r['supplierPhone'] as String?),
            supplierId: Value(r['supplierId'] as String?),
            purchaseOrderId: Value(r['purchaseOrderId'] as String?),
            note: Value(r['note'] as String?),
            recordedById: r['recordedById'] as String,
            clientCreatedAt: DateTime.parse(r['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(r['updatedAt'] as String),
          ),
        );
        for (final line
            in (r['lines'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>()) {
          await into(purchaseReceiptLinesLocal).insertOnConflictUpdate(
            PurchaseReceiptLinesLocalCompanion.insert(
              id: line['id'] as String,
              receiptId: r['id'] as String,
              productId: line['productId'] as String,
              qty: line['qty'] as String,
              unitCostVnd: Value(line['unitCostVnd'] as int?),
            ),
          );
        }
      }
      for (final w in wastageVouchers) {
        await into(wastageVouchersLocal).insertOnConflictUpdate(
          WastageVouchersLocalCompanion.insert(
            id: w['id'] as String,
            storeId: w['storeId'] as String,
            reasonCode: w['reasonCode'] as String,
            note: Value(w['note'] as String?),
            recordedById: w['recordedById'] as String,
            clientCreatedAt: DateTime.parse(w['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(w['updatedAt'] as String),
          ),
        );
        for (final line
            in (w['lines'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>()) {
          await into(wastageVoucherLinesLocal).insertOnConflictUpdate(
            WastageVoucherLinesLocalCompanion.insert(
              id: line['id'] as String,
              wastageId: w['id'] as String,
              productId: line['productId'] as String,
              qty: line['qty'] as String,
            ),
          );
        }
      }
      for (final m in stockMovements) {
        await into(stockMovementsLocal).insertOnConflictUpdate(
          StockMovementsLocalCompanion.insert(
            id: m['id'] as String,
            storeId: m['storeId'] as String,
            productId: m['productId'] as String,
            qtyDelta: m['qtyDelta'] as String,
            balanceAfter: m['balanceAfter'] as String,
            docType: m['docType'] as String,
            docId: m['docId'] as String,
            docLineId: Value(m['docLineId'] as String?),
            recordedById: m['recordedById'] as String,
            clientCreatedAt: DateTime.parse(m['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(m['updatedAt'] as String),
          ),
        );
      }
    });
  }

  Future<void> upsertCustomersAndDebtLedger({
    required List<Map<String, dynamic>> customers,
    required List<Map<String, dynamic>> debtLedger,
  }) async {
    await transaction(() async {
      for (final c in customers) {
        await into(customersLocal).insertOnConflictUpdate(
          CustomersLocalCompanion.insert(
            id: c['id'] as String,
            name: c['name'] as String,
            phone: Value(c['phone'] as String?),
            balanceVnd: Value(c['balanceVnd'] as int),
            creditLimitVnd: Value(c['creditLimitVnd'] as int?),
            updatedAt: DateTime.parse(c['updatedAt'] as String),
          ),
        );
      }
      for (final e in debtLedger) {
        await into(debtLedgerLocal).insertOnConflictUpdate(
          DebtLedgerLocalCompanion.insert(
            id: e['id'] as String,
            storeId: e['storeId'] as String,
            customerId: e['customerId'] as String,
            type: e['type'] as String,
            amountVnd: e['amountVnd'] as int,
            balanceAfterVnd: e['balanceAfterVnd'] as int,
            saleId: Value(e['saleId'] as String?),
            shiftId: Value(e['shiftId'] as String?),
            recordedById: e['recordedById'] as String,
            paymentMethod: Value(e['paymentMethod'] as String?),
            note: Value(e['note'] as String?),
            clientCreatedAt: DateTime.parse(e['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(e['updatedAt'] as String),
          ),
        );
      }
    });
  }

  Future<void> upsertProductsAndStocks({
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> stocks,
    List<Map<String, dynamic>> productGroups = const [],
    List<Map<String, dynamic>> comboComponents = const [],
  }) async {
    await transaction(() async {
      for (final group in productGroups) {
        await into(this.productGroups).insertOnConflictUpdate(
          ProductGroupsCompanion.insert(
            id: group['id'] as String,
            name: group['name'] as String,
            sortOrder: Value(group['sortOrder'] as int? ?? 0),
            active: Value(group['active'] as bool? ?? true),
            updatedAt: DateTime.parse(group['updatedAt'] as String),
          ),
        );
      }
      for (final product in products) {
        await into(this.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: product['id'] as String,
            sku: product['sku'] as String,
            barcode: Value(product['barcode'] as String?),
            name: product['name'] as String,
            unit: product['unit'] as String,
            sellUnit: Value(product['sellUnit'] as String?),
            packSize: Value(product['packSize']?.toString()),
            kind: Value(product['kind'] as String? ?? 'normal'),
            groupId: Value(product['groupId'] as String?),
            isWeighted: Value(product['isWeighted'] as bool? ?? false),
            basePriceVnd: product['basePriceVnd'] as int,
            costVnd: Value(product['costVnd'] as int? ?? 0),
            active: Value(product['active'] as bool? ?? true),
            updatedAt: DateTime.parse(product['updatedAt'] as String),
          ),
        );
      }
      for (final component in comboComponents) {
        await into(productComboComponents).insertOnConflictUpdate(
          ProductComboComponentsCompanion.insert(
            id: component['id'] as String,
            comboProductId: component['comboProductId'] as String,
            componentProductId: component['componentProductId'] as String,
            qtyBase: component['qtyBase'].toString(),
          ),
        );
      }

      for (final stock in stocks) {
        await into(productStocks).insertOnConflictUpdate(
          ProductStocksCompanion.insert(
            productId: stock['productId'] as String,
            storeId: stock['storeId'] as String,
            qty: stock['qty'] as String,
            minQty: stock['minQty'] as String,
            avgCostVnd: Value(stock['avgCostVnd'] as int? ?? 0),
            updatedAt: DateTime.parse(stock['updatedAt'] as String),
          ),
        );
      }
    });
  }

  /// Chỉ lấy entry `pending` đã tới lượt retry — `nextRetryAt` null (chưa
  /// từng lỗi hạ tầng lần nào) hoặc đã ở trong quá khứ. Entry đang chờ
  /// backoff (`nextRetryAt` ở tương lai, xem
  /// `outbox_worker.dart::recordOutboxInfraFailure`) bị loại khỏi batch tới
  /// khi tick kế tiếp gọi hàm này — đây chính là cơ chế backoff: không cần
  /// một scheduler riêng, `pendingOutbox()` tự "im lặng" với các entry chưa
  /// tới hạn.
  Future<List<OutboxEntry>> pendingOutbox({int limit = 50}) {
    final now = DateTime.now();
    return (select(outboxEntries)
          ..where(
            (entry) =>
                entry.status.equals('pending') &
                (entry.nextRetryAt.isNull() |
                    entry.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(entry) => OrderingTerm.asc(entry.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Đưa một entry (kể cả đã `dead_letter`) trở lại hàng đợi retry tự động.
  /// Reset cả `retryCount`/`nextRetryAt` về trạng thái "chưa từng lỗi hạ
  /// tầng lần nào" — nếu không reset, một entry dead-letter được người dùng
  /// bấm "Thử lại" mà lỡ gặp đúng 1 lỗi hạ tầng nữa sẽ dead-letter lại NGAY
  /// (retryCount đã sẵn vượt ngưỡng từ trước), rất khó hiểu với người dùng
  /// vừa chủ động thử lại.
  Future<void> requeueOutbox(String outboxId) async {
    await (update(
      outboxEntries,
    )..where((row) => row.id.equals(outboxId))).write(
      const OutboxEntriesCompanion(
        status: Value('pending'),
        lastError: Value(null),
        retryCount: Value(0),
        nextRetryAt: Value(null),
      ),
    );
  }

  /// Gồm cả `'error'` (server từ chối nghiệp vụ — cần người dùng sửa dữ
  /// liệu) lẫn `'dead_letter'` (hết lượt retry hạ tầng — chỉ cần thử lại
  /// khi mạng/server đã ổn). Cả hai đều cần một người xem qua, nên gộp
  /// chung một danh sách cho màn "Đồng bộ lỗi" (`OutboxConflictsPage`) thay
  /// vì tách hai màn — UI tự phân biệt bằng `status` (xem
  /// `outbox_conflicts_page.dart`).
  Future<List<OutboxEntry>> listOutboxErrors() {
    return (select(outboxEntries)
          ..where(
            (row) =>
                row.status.equals('error') | row.status.equals('dead_letter'),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Stream<int> watchOutboxErrorCount() {
    return (select(outboxEntries)
          ..where(
            (row) =>
                row.status.equals('error') | row.status.equals('dead_letter'),
          ))
        .watch()
        .map((rows) => rows.length);
  }

  /// Ghi nhận một lượt push `/sync/push` thất bại do lỗi HẠ TẦNG (mất mạng,
  /// server sập, timeout — bắt ở `on DioException` trong
  /// `outbox_worker.dart::tick()`), KHÔNG phải bị server từ chối nghiệp vụ
  /// (nhánh đó dùng `markOutboxError`, không đụng tới ở đây).
  ///
  /// [entries] phải là đúng danh sách entry đã nằm trong batch vừa gửi thất
  /// bại (biến `pending` mà `tick()` đã fetch qua `pendingOutbox()` ở đầu
  /// hàm) — dùng thẳng `retryCount` đọc được lúc đó làm mốc, không đọc lại
  /// từ DB (không có ai khác ghi xen vào giữa lúc fetch và lúc catch trong
  /// cùng một lượt `tick()`).
  ///
  /// Với mỗi entry: tăng `retryCount`. Nếu con số mới còn trong hạn
  /// [maxRetries], đặt `nextRetryAt = now + backoffFor(retryCount mới)` để
  /// `pendingOutbox()` bỏ qua entry này tới lúc đó (xem tài liệu ở đó). Nếu
  /// vượt hạn, chuyển hẳn sang `status = 'dead_letter'` — loại khỏi vòng
  /// lặp retry tự động vĩnh viễn, chỉ còn cách quay lại `pending` qua
  /// `requeueOutbox` (màn "Đồng bộ lỗi", giống hệt cơ chế của `'error'`).
  Future<void> recordOutboxInfraFailure(
    List<OutboxEntry> entries, {
    required Duration Function(int retryCount) backoffFor,
    required int maxRetries,
  }) async {
    if (entries.isEmpty) {
      return;
    }
    final now = DateTime.now();
    for (final entry in entries) {
      final retryCount = entry.retryCount + 1;
      if (retryCount > maxRetries) {
        await (update(
          outboxEntries,
        )..where((row) => row.id.equals(entry.id))).write(
          OutboxEntriesCompanion(
            status: const Value('dead_letter'),
            retryCount: Value(retryCount),
            nextRetryAt: const Value(null),
            lastError: const Value(outboxSyncRetryExhaustedReason),
          ),
        );
      } else {
        await (update(
          outboxEntries,
        )..where((row) => row.id.equals(entry.id))).write(
          OutboxEntriesCompanion(
            retryCount: Value(retryCount),
            nextRetryAt: Value(now.add(backoffFor(retryCount))),
          ),
        );
      }
    }
  }

  Future<void> updateOutboxPayload(String outboxId, String payloadJson) {
    return (update(outboxEntries)..where((row) => row.id.equals(outboxId)))
        .write(OutboxEntriesCompanion(payloadJson: Value(payloadJson)));
  }

  Future<void> markOutboxDone(List<String> saleIds) async {
    await markOutboxEntitiesDone('sale', saleIds);
  }

  Future<void> markOutboxEntitiesDone(
    String entityType,
    List<String> entityIds,
  ) async {
    if (entityIds.isEmpty) {
      return;
    }
    final pending = await pendingOutbox(limit: 500);
    final accepted = entityIds.toSet();
    for (final entry in pending) {
      if (entry.entityType != entityType) {
        continue;
      }
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      final entityId = payload['id'] as String?;
      if (entityId == null || !accepted.contains(entityId)) {
        continue;
      }
      await (update(outboxEntries)..where((row) => row.id.equals(entry.id)))
          .write(const OutboxEntriesCompanion(status: Value('done')));
      if (entityType == 'sale') {
        await (update(salesLocal)..where((row) => row.id.equals(entityId)))
            .write(SalesLocalCompanion(syncedAt: Value(DateTime.now())));
      }
    }
  }

  Future<void> markOutboxError(
    String entityId,
    String reason, {
    String? entityType,
  }) async {
    final pending = await pendingOutbox(limit: 500);
    for (final entry in pending) {
      if (entityType != null && entry.entityType != entityType) {
        continue;
      }
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      if (payload['id'] != entityId) {
        continue;
      }
      await (update(
        outboxEntries,
      )..where((row) => row.id.equals(entry.id))).write(
        OutboxEntriesCompanion(
          status: const Value('error'),
          lastError: Value(reason),
        ),
      );
    }
  }

  /// Hoàn tác tác động local của một lần thu nợ khi server từ chối vĩnh viễn.
  ///
  /// Cộng lại `balanceVnd` cho khách đúng bằng số tiền đã trừ và xóa dòng
  /// `debtLedgerLocal` tương ứng, trong một transaction duy nhất.
  ///
  /// Idempotent: dòng ledger local là "cờ" duy nhất — nếu nó không còn (đã hoàn
  /// tác trước đó, hoặc bản ghi chưa từng được ghi local) thì không cộng gì cả.
  /// Trả về `true` khi thực sự có hoàn tác.
  Future<bool> revertLocalDebtPayment(String paymentId) {
    return transaction(() async {
      final ledger =
          await (select(debtLedgerLocal)..where(
                (row) => row.id.equals(paymentId) & row.type.equals('payment'),
              ))
              .getSingleOrNull();
      if (ledger == null) {
        return false;
      }
      final removed =
          await (delete(debtLedgerLocal)..where(
                (row) => row.id.equals(paymentId) & row.type.equals('payment'),
              ))
              .go();
      if (removed == 0) {
        return false;
      }
      final customer = await (select(
        customersLocal,
      )..where((row) => row.id.equals(ledger.customerId))).getSingleOrNull();
      if (customer == null) {
        return true;
      }
      await (update(
        customersLocal,
      )..where((row) => row.id.equals(customer.id))).write(
        CustomersLocalCompanion(
          balanceVnd: Value(customer.balanceVnd + ledger.amountVnd),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return true;
    });
  }

  Stream<SyncStatusSnapshot> watchSyncStatus() {
    final query = select(outboxEntries)
      ..where(
        (entry) =>
            entry.status.equals('pending') | entry.status.equals('error'),
      )
      ..orderBy([(entry) => OrderingTerm.desc(entry.createdAt)]);

    return query.watch().map((entries) {
      final pendingCount = entries
          .where(
            (entry) => entry.status == 'pending' && entry.entityType == 'sale',
          )
          .length;
      final lastError = entries
          .where((entry) => entry.status == 'error' && entry.lastError != null)
          .map((entry) => entry.lastError!)
          .firstOrNull;
      return SyncStatusSnapshot(
        pendingCount: pendingCount,
        lastError: lastError,
      );
    });
  }
}

class SyncStatusSnapshot {
  const SyncStatusSnapshot({required this.pendingCount, this.lastError});

  final int pendingCount;
  final String? lastError;

  bool get isVisible => pendingCount > 0 || lastError != null;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'tap_hoa_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
