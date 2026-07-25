# Task 8 Report

- Added POS day report `byShift` model parsing and offline local shift aggregation, and displayed a "Doanh thu theo ca" section on the day report page.
- Added POS aggregate debt-aging models plus an owner/store-manager aggregate debt section that calls `/reports/debt-aging` with `storeId` omitted; cashier local/offline debt list behavior remains unchanged.
- Added owner/store-manager AR CSV export/share from `/reports/ar.csv` on the debt customer list page.
- Tests: `flutter test test/day_report_repository_test.dart test/debt_aging_test.dart` (apps/pos_app).
- Analysis: `flutter analyze lib/features/reports/day_report_repository.dart lib/features/reports/day_report_page.dart lib/features/customers/debt_aging.dart lib/features/customers/debt_customer_list_page.dart test/day_report_repository_test.dart test/debt_aging_test.dart` (apps/pos_app).
- Note: full `flutter analyze` still reports pre-existing info-level issues in `inventory_hub_page.dart` and `ledger_page.dart`.
