# Task 12 Report

## Offline customer debt sync fix

- Root cause: offline-created customers stayed local-only; debt sale push failed with `customer_not_found`.
- Fix: debt checkout outbox payload now embeds `customer {id,name,phone}`; sync upserts customer before applying debt.
- `POST /customers` already upserts by client id; no OutboxWorker ordering change needed.
- Added API e2e for offline-style UUID customer + embedded debt sale push.
