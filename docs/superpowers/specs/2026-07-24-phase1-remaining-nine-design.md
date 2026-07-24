# Thiết kế: Quy đổi đơn vị

**Ngày:** 2026-07-24 — `unit` = base; `sellUnit` + `packSize`; `toBaseQty`.

# Thiết kế: Sổ nợ quá hạn

FIFO `sale_debt` covered by payments; `Store.debtOverdueDays` default 30; `GET /reports/debt-aging`.

# Thiết kế: ESC/POS Windows

`buildReceiptEscPosBytes` + PDF fallback; MetaLocal `receiptPrintMode`.

# Thiết kế: Đổi trả trong ngày

`SaleReturn` same ICT day; role owner|store_manager; outbox `sale_return`.

# Thiết kế: Combo

`kind=combo` + `ProductComboComponent`; checkout trừ component stock.

# Thiết kế: FCM push

`POST /devices/push-token`; client PushService + optional firebase-admin when `FIREBASE_SERVICE_ACCOUNT` is set. Sync reject + low-stock alerts wired (see polish design).

# Thiết kế: CSV doanh thu

`dayReportToCsv` UTF-8 BOM; nút trên DayReportPage.

# Thiết kế: Sync diagnostics

`GET /sync/diagnostics`; SyncDiagnosticsPage.
