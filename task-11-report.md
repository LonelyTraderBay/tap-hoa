# Task 11 Report

## Day report review fixes

- API `parseDateRange` and Flutter offline aggregation now use Asia/Ho_Chi_Minh (UTC+7) day start/end as UTC instants.
- `DayReportRepository` only falls back to `SalesLocal` on Dio network errors (timeout, connection, unknown); 401/403/500 rethrow.
- Owner `DayReportPage` fetches consolidated report without `storeId` when online; staff remain store-scoped via `role` from session.
- Added ICT date unit tests, repository offline/error tests, and e2e boundary case for ICT midnight.
