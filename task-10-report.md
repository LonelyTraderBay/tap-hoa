# Task 10 Report

## Sync banner fixes

- `watchSyncStatus` pending count now filters `entityType == 'sale'` so the banner matches what `OutboxWorker` actually pushes (shift_open entries no longer inflate the count).
- `SyncStatusBanner` wrapped in `SafeArea(bottom: false)` inside `MaterialApp.builder` to respect top inset without adding bottom padding.
- Added widget tests: non-sale pending entries hidden; PosApp SafeArea wrapper verified.
