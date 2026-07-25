# Multi-device smoke (Wave B — Task B.1)

Run after Wave A go-live ([go-live-checklist.md](go-live-checklist.md)) on **≥ 2 POS
devices** pointed at the same production API and store. Record pass/fail in an
internal note or issue — do not commit store credentials or sale data.

**Prerequisites:**

- Wave A done: API healthy, real owner login, ≥ 1 device passed single-machine smoke
  ([windows-prod.md](windows-prod.md) or [android-release.md](android-release.md)).
- Device A and Device B: same store (`CH`), same owner/staff accounts, prod `API_URL`.

**Setup:** Label machines **Máy A** (primary counter) and **Máy B** (second pull
device). Use known SKUs with visible stock before starting.

---

## Operator checklist

### Máy A — offline queue, then sync

- [ ] **Máy A offline** — disconnect network (Wi‑Fi off or unplugged).
- [ ] **Mở ca** — open shift with opening cash on Máy A only.
- [ ] **Bán nợ + TM** — complete at least one credit (nợ) sale and one cash (TM) sale
  while still offline.
- [ ] **Online + Đồng bộ** — restore network; run **Đồng bộ** (or wait for auto sync).
- [ ] **Sync order** — confirm server received events in order: `shift_open` before
  `sale` (no “shift not open” or duplicate-shift errors in sync log).

### Máy B — pull and day report

- [ ] **Máy B pull** — on Máy B (online), run **Đồng bộ** or restart app so it pulls
  from server.
- [ ] **Tồn giảm** — stock for sold SKUs decreased on Máy B to match Máy A sales.
- [ ] **Báo cáo ngày khớp** — day report on A and B shows the same revenue / sale
  count for today.

### Máy A — close shift with variance

- [ ] **Đóng ca A** — on Máy A, close shift with expected vs actual cash count.
- [ ] **Lệch + ghi chú OK** — enter a deliberate small variance and a note; confirm
  close succeeds and syncs without blocking.

### Owner — period / VAT / export (once)

- [ ] **Sổ kỳ** — owner opens period ledger / trial balance for the store; numbers
  reflect synced sales.
- [ ] **VAT** — if VAT is enabled for the store, spot-check VAT report for the test
  day.
- [ ] **Excel hoặc PDF** — export period report once (Excel or PDF); file opens and
  Vietnamese labels render (PDF Unicode: see Wave B plan if glyphs fail).

---

## Wave B.1 definition of done

- [ ] All checkboxes above passed on live prod (or staging mirror with real multi-device
  flow).
- [ ] No unresolved sync errors; stock and day reports consistent across devices.
- [ ] Shift close with variance + note accepted and visible after sync.

**Next:** optional FCM ([fcm.md](fcm.md)); period PDF font fix (Wave B.3 in repo plan).
