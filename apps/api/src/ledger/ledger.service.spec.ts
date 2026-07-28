import { Role } from '@prisma/client';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';
import { LedgerService } from './ledger.service';

/**
 * G2 (docs/superpowers/plans/2026-07-28-va-gap-audit-spec.md): `defaultAuditActions`
 * là allowlist dùng làm bộ lọc MẶC ĐỊNH cho `GET /ledger/audit` khi client không
 * truyền `action` — đây là cách màn "Sổ · Nhật ký" trên Flutter (`ledger_page.dart`,
 * hàm `listAudit`) luôn gọi endpoint này. Nếu một action string được ghi thật vào
 * `AuditLog` (qua `auditLog.create(...)`) mà thiếu trong allowlist, bản ghi tồn tại
 * trong DB nhưng vĩnh viễn không hiện lên UI cho chủ quán xem.
 *
 * Danh sách dưới đây là kết quả grep toàn bộ `apps/api/src` cho `auditLog.create(`
 * tại thời điểm audit (2026-07-28) — mọi action string thật hiện có trong code,
 * kèm evidence nơi ghi:
 *  - `ledger.service.ts` (qua `writeAudit`, private helper): `period_lock`,
 *    `period_unlock`, `journal_blocked_period_lock`, `journal_post_failed`
 *    (dòng ~149-155, gọi từ `safePost` — fail-soft wrapper dùng ở
 *    suppliers/sync/stock-ops services khi bút toán post lỗi).
 *  - `einvoice.service.ts` (qua `writeEinvoiceAudit`, tham số `action` gõ kiểu
 *    union `'einvoice_issue' | 'einvoice_cancel' | 'einvoice_adjust'` nên chỉ
 *    có đúng 3 giá trị này).
 *  - `users.service.ts`: `user_create`, `user_role_change`, `user_password_reset`.
 *  - `products.service.ts:262`: `product_price_change`.
 *  - `sync/sale-returns.service.ts:266`: `sale_return_create` (đã thêm ở G1).
 *  - `customers.service.ts:155`: `debt_adjust` (G2 — phát hiện thiếu, đã bổ sung).
 *  - `reports.service.ts:1779`: `bank_recon_locked` (G2 — phát hiện thiếu, đã bổ sung).
 *  - `reports.service.ts:2184`: `ap_recon_locked` (G2 — phát hiện thiếu, đã bổ sung).
 *
 * Test này không cần biết trước tên action (đúng tinh thần DoD G2): nó gọi thẳng
 * `listAudit()` không truyền `action` (y hệt cách `GET /ledger/audit` xử lý khi
 * client — vd Flutter — không truyền query param `action`) rồi khẳng định filter
 * `where.action.in` thật sự được dùng để query Prisma chứa đủ toàn bộ danh sách
 * trên. `debt_adjust` còn được xác nhận thêm qua HTTP thật trong
 * `test/customers-debt-adjust.e2e-spec.ts`.
 */
const ALL_REAL_AUDIT_ACTIONS = [
  'period_lock',
  'period_unlock',
  'journal_blocked_period_lock',
  'journal_post_failed',
  'einvoice_issue',
  'einvoice_cancel',
  'einvoice_adjust',
  'user_create',
  'user_role_change',
  'user_password_reset',
  'product_price_change',
  'sale_return_create',
  'debt_adjust',
  'bank_recon_locked',
  'ap_recon_locked',
];

describe('LedgerService.listAudit default action allowlist (G2)', () => {
  function buildService() {
    const findMany = jest.fn().mockResolvedValue([]);
    const fakePrisma = {
      auditLog: { findMany },
    } as unknown as PrismaService;
    const service = new LedgerService(fakePrisma);
    return { service, findMany };
  }

  const owner: AuthUser = {
    userId: 'owner-1',
    role: Role.owner,
    storeIds: [],
    canLedger: true,
    canEinvoice: true,
  };

  it('default allowlist covers every real AuditLog action string found in apps/api/src', async () => {
    const { service, findMany } = buildService();

    await service.listAudit(owner, {});

    expect(findMany).toHaveBeenCalledTimes(1);
    const where = findMany.mock.calls[0][0].where as {
      action: { in: string[] };
    };
    expect(where.action.in).toEqual(
      expect.arrayContaining(ALL_REAL_AUDIT_ACTIONS),
    );
    // Không action nào bị khai trùng trong allowlist.
    expect(new Set(where.action.in).size).toBe(where.action.in.length);
  });

  it('uses the explicit `action` filter (not the allowlist) when the caller passes one', async () => {
    const { service, findMany } = buildService();

    await service.listAudit(owner, { action: 'debt_adjust' });

    const where = findMany.mock.calls[0][0].where as { action: unknown };
    expect(where.action).toBe('debt_adjust');
  });
});
