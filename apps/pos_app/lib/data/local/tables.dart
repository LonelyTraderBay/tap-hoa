import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text().unique()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  BoolColumn get isWeighted => boolean().withDefault(const Constant(false))();
  IntColumn get basePriceVnd => integer()();
  IntColumn get costVnd => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductStocks extends Table {
  TextColumn get productId => text()();
  TextColumn get storeId => text()();
  TextColumn get qty => text()();
  TextColumn get minQty => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId, storeId};
}

class OutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text()
      .check(
        const CustomExpression<bool>("status IN ('pending', 'error', 'done')"),
      )
      .withDefault(const Constant('pending'))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SalesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get shiftId => text()();
  TextColumn get paymentMethod => text()();
  IntColumn get totalVnd => integer()();
  IntColumn get cashAmount => integer()();
  IntColumn get transferAmount => integer()();
  IntColumn get debtAmount => integer()();
  TextColumn get customerId => text().nullable()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SaleLinesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get productId => text()();
  TextColumn get qty => text()();
  IntColumn get unitPrice => integer()();
  IntColumn get lineTotal => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShiftsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get openingCash => integer()();
  IntColumn get closingCash => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get expectedCashVnd => integer().nullable()();
  IntColumn get varianceVnd => integer().nullable()();
  IntColumn get transferInShiftVnd => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StoresLocal extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class MetaLocal extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

class CustomersLocal extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get balanceVnd => integer().withDefault(const Constant(0))();
  IntColumn get creditLimitVnd => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DebtLedgerLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get customerId => text()();
  TextColumn get type => text()(); // sale_debt | payment
  IntColumn get amountVnd => integer()();
  IntColumn get balanceAfterVnd => integer()();
  TextColumn get saleId => text().nullable()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get recordedById => text()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CashCategoriesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get direction => text()(); // in | out
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class CashVouchersLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get shiftId => text()();
  TextColumn get categoryId => text()();
  TextColumn get direction => text()();
  TextColumn get channel => text()(); // cash | transfer
  IntColumn get amountVnd => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get recordedById => text()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StockTransfersLocal extends Table {
  TextColumn get id => text()();
  TextColumn get fromStoreId => text()();
  TextColumn get toStoreId => text()();
  TextColumn get status => text()(); // draft|approved|rejected|received
  TextColumn get note => text().nullable()();
  TextColumn get createdById => text()();
  TextColumn get approvedById => text().nullable()();
  TextColumn get receivedById => text().nullable()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StockTransferLinesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get transferId => text()();
  TextColumn get productId => text()();
  TextColumn get qty => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class StocktakesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get note => text().nullable()();
  TextColumn get recordedById => text()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StocktakeLinesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get stocktakeId => text()();
  TextColumn get productId => text()();
  TextColumn get systemQty => text()();
  TextColumn get countedQty => text()();
  TextColumn get varianceQty => text()();
  TextColumn get reason => text()();
  TextColumn get reasonNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PurchaseReceiptsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get supplierName => text()();
  TextColumn get supplierPhone => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get recordedById => text()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PurchaseReceiptLinesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text()();
  TextColumn get productId => text()();
  TextColumn get qty => text()();
  IntColumn get unitCostVnd => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WastageVouchersLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get reasonCode => text()();
  TextColumn get note => text().nullable()();
  TextColumn get recordedById => text()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class WastageVoucherLinesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get wastageId => text()();
  TextColumn get productId => text()();
  TextColumn get qty => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class StockMovementsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get productId => text()();
  TextColumn get qtyDelta => text()();
  TextColumn get balanceAfter => text()();
  TextColumn get docType => text()();
  TextColumn get docId => text()();
  TextColumn get docLineId => text().nullable()();
  TextColumn get recordedById => text()();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
