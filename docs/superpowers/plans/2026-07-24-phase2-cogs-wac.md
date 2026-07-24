# Phase 2 Epic 1 — COGS WAC Implementation Plan

> **For agentic workers:** Use subagent-driven-development or executing-plans. Checkboxes track progress.

**Goal:** Per-store weighted-average cost + sale-line COGS snapshot; reports use real WAC.

**Architecture:** Pure `weightedAverageCost` helper; update on purchase; snapshot on sale push; pull `avgCostVnd` to Drift.

**Tech Stack:** Prisma, NestJS, Flutter Drift

## Global Constraints

- Method fixed to WAC (see design).
- Offline-first: local purchase updates avg before sync.
- Do not break existing sale push without unitCost.

### Task 1: Schema + WAC helper + purchase/sale/reports

- [x] Migration + Prisma fields
- [x] `weightedAverageCost` unit tests
- [x] Wire purchase + sale + topSkus/stockOnHand
- [x] e2e COGS

### Task 2: Flutter Drift v7 + local purchase/checkout

- [x] `avgCostVnd` on stocks; `unitCostVnd` on sale lines
- [x] Pull + inventory WAC + checkout snapshot

### Task 3: Docs

- [x] Spec + this plan; parent design §9 pointer
