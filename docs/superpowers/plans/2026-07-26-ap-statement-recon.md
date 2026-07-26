# Wave C — AP statement reconciliation

## Goal

Add supplier-scoped AP statement reconciliation that mirrors the existing bank reconciliation flow: idempotent CSV import, read-only summaries with suggested matches, explicit match/unmatch/auto-match, and period locking once variance is zero and all lines are matched.

## Backend plan

- Add Prisma models:
  - `ApStatementLine`: `storeId`, `supplierId`, `periodYm`, `bookedAt`, `amountVnd`, `memo`, `matchedRef`, `fingerprint`, `matchVersion`.
  - `ApReconLock`: unique by `storeId + supplierId + periodYm`, with `lockedById` and `lockedAt`.
- Keep import CSV format minimal and parallel to bank recon: `date,amountVnd,memo`; amount is payable/payment statement amount from the supplier statement.
- Fingerprint imports by store, supplier, period, date, amount, and memo with `createMany(...skipDuplicates)` so re-imports are safe.
- Expose API under `/reports/ap-recon*`:
  - `POST /import`
  - `GET /`
  - `POST /match`
  - `POST /unmatch`
  - `POST /auto-match`
  - `POST /lock`
- Authorize owner and store manager only, with normal store access checks.
- Build AP book lines from:
  - `SupplierPayment` as negative amounts (`supplier_pay:<id>`).
  - `SupplierPayable` original payable amounts as positive amounts (`supplier_payable:<id>`).
- Match only exact amount within the period/date window, with memo/ref overlap boosting score.
- Keep GET read-only: suggestions are returned but never persisted until match/auto-match/lock.
- Lock only when variance is zero and all statement/book lines are persisted matched; auto-apply complete suggestions before locking, like bank recon.

## Flutter plan

- Add a supplier AP reconciliation page next to the current supplier debt page.
- Reuse the bank recon UI pattern for period, CSV paste/import, summary totals, statements, suggestions, manual match/unmatch, auto-match, lock, and refresh.
- Link it from the existing “Công nợ NCC” supplier screen so accounting users can open reconciliation in context.

## Verification

- Add `ap-recon.e2e-spec.ts` covering import idempotency, read-only GET, auto-match, manual unmatch/rematch, lock, and locked import rejection.
- Run the targeted API e2e suite.
- Run Flutter analysis after adding the page.
