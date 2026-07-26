# Wave E — ledger vs e-invoice permissions

## Goal

Tách quyền xem sổ kế toán và xuất HĐĐT để quản lý có thể được cấp từng quyền riêng, trong khi chủ quán luôn có cả hai và thu ngân không có quyền nào.

## Plan

1. Add `User.canLedger` / `User.canEinvoice` booleans with owner seed/bootstrap defaults.
2. Return effective flags from login/JWT validation: owner always both, store manager by flags, cashier none.
3. Protect `/ledger/*` and `/einvoices/*` with dedicated Nest guards, keeping owner-only period lock/unlock rules in the ledger service.
4. Gate Flutter POS toolbar actions for **Sổ kế toán** and **Xuất HĐĐT** by effective flags.
5. Cover the role/flag matrix with e2e tests and keep existing ledger store-scoping coverage.
