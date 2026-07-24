# Specs Phase 1 remaining (brief)

See master plan. Individual notes:

- **unit-conversion**: `unit` = base; `sellUnit`+`packSize`; stock always base.
- **debt-aging**: FIFO cover payments; Store.debtOverdueDays default 30.
- **escpos-windows**: Win32 raw WritePrinter + MetaLocal `receiptPrintMode`/`receiptPrinterName`; PDF fallback.
- **sale-returns**: same ICT day; owner|store_manager; refund split cash/transfer/debtCredit; outbox `sale_return`.
- **combo-products**: kind=combo; UI component picker; empty combo rejected; checkout decrements components.
- **fcm-push**: DevicePushToken + optional firebase-admin; sync reject + low-stock alerts; no-op without Firebase.
- **csv-day-revenue**: dayReportToCsv + DayReportPage export (store code/name from storesLocal).
- **sync-diagnostics**: GET /sync/diagnostics + SyncDiagnosticsPage.
- **polish**: `docs/superpowers/specs/2026-07-24-phase1-polish-design.md`
