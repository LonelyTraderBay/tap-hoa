import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

const CATEGORY_ELECTRICITY = 'a1000000-0000-4000-8000-000000000002';

describe('Phase 3 bank recon e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
  let productId: string;
  let periodYm: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    prisma = moduleRef.get(PrismaService);
    await app.init();
    await seedChartOfAccounts(prisma);

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phone: '0900000001', password: '123456' })
      .expect(201);
    token = login.body.accessToken;
    userId = login.body.user.id;
    storeId = (await prisma.store.findFirst({ where: { code: 'CH1' } }))!.id;
    productId = (
      await prisma.product.findUnique({ where: { sku: 'STING-330' } })
    )!.id;
    const now = new Date();
    const ict = new Date(now.getTime() + 7 * 3600_000);
    periodYm = `${ict.getUTCFullYear()}-${String(ict.getUTCMonth() + 1).padStart(2, '0')}`;
  });

  afterAll(async () => {
    await app.close();
  });

  it('imports statement, matches sale transfer, locks period', async () => {
    await prisma.bankReconLock.deleteMany({ where: { storeId, periodYm } });
    await prisma.bankStatementLine.deleteMany({ where: { storeId, periodYm } });
    await prisma.shift.updateMany({
      where: { storeId, closedAt: null },
      data: { closedAt: new Date(), closingCash: 0 },
    });
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId, storeId } },
      create: {
        productId,
        storeId,
        qty: 20,
        minQty: 0,
        avgCostVnd: 9000,
      },
      update: { qty: 20, avgCostVnd: 9000 },
    });
    const shift = await prisma.shift.create({
      data: {
        id: randomUUID(),
        storeId,
        userId,
        openedAt: new Date(),
        openingCash: 0,
      },
    });
    const saleId = randomUUID();
    await request(app.getHttpServer())
      .post('/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceId: 'bank-recon-1',
        sales: [
          {
            id: saleId,
            storeId,
            shiftId: shift.id,
            paymentMethod: 'transfer',
            cashAmount: 0,
            transferAmount: 50_000,
            debtAmount: 0,
            discountVnd: 0,
            totalVnd: 50_000,
            clientCreatedAt: new Date().toISOString(),
            lines: [
              {
                productId,
                qty: '1',
                unitPrice: 50_000,
                lineTotal: 50_000,
              },
            ],
          },
        ],
      })
      .expect(201);

    const day = periodYm + '-15';
    const imp = await request(app.getHttpServer())
      .post('/reports/bank-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        periodYm,
        csv: `date,amountVnd,memo\n${day},50000,CK ban`,
      })
      .expect(201);
    expect(imp.body.imported).toBe(1);

    const summary = await request(app.getHttpServer())
      .get('/reports/bank-recon')
      .query({ storeId, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(summary.body.bookTotalVnd).toBe(50_000);
    expect(summary.body.statementTotalVnd).toBe(50_000);
    expect(summary.body.varianceVnd).toBe(0);
    // GET is read-only — suggestions only until auto-match / lock
    expect(summary.body.suggestedMatchCount).toBe(1);
    expect(summary.body.statements[0].matchedRef).toBeNull();

    const again = await request(app.getHttpServer())
      .get('/reports/bank-recon')
      .query({ storeId, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(again.body.statements[0].matchedRef).toBeNull();

    await request(app.getHttpServer())
      .post('/reports/bank-recon/auto-match')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId, periodYm })
      .expect(201);

    const matched = await request(app.getHttpServer())
      .get('/reports/bank-recon')
      .query({ storeId, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(matched.body.matchedCount).toBe(1);

    await request(app.getHttpServer())
      .post('/reports/bank-recon/lock')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId, periodYm })
      .expect(201);

    await request(app.getHttpServer())
      .post('/reports/bank-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        periodYm,
        csv: `${day},1000,x`,
      })
      .expect(400);
  });

  describe('P2.2 — POST /reports/bank-recon/create-entry', () => {
    // Reset toàn bộ book-side (sale/voucher/supplier payment/journal) của CH1
    // trước MỖI test dưới đây — bắt buộc vì các test lock() cần
    // unmatchedBookCount === 0 tuyệt đối; nếu không dọn, sale chuyển khoản
    // 50.000 mà test đầu file (khai báo TRƯỚC describe này) để lại sẽ luôn
    // hiện ra như một dòng book "chưa khớp" (nó không có statement tương
    // ứng trong các test dưới đây) và làm lock() thất bại giả.
    async function resetBookSide() {
      await prisma.journalLine.deleteMany({ where: { entry: { storeId } } });
      await prisma.journalEntry.deleteMany({ where: { storeId } });
      await prisma.eInvoice.deleteMany({ where: { sale: { storeId } } });
      await prisma.saleReturnLine.deleteMany({
        where: { saleReturn: { storeId } },
      });
      await prisma.saleReturn.deleteMany({ where: { storeId } });
      await prisma.saleLine.deleteMany({ where: { sale: { storeId } } });
      await prisma.sale.deleteMany({ where: { storeId } });
      await prisma.cashVoucher.deleteMany({ where: { storeId } });
      await prisma.supplierPayment.deleteMany({ where: { storeId } });
      await prisma.bankReconLock.deleteMany({ where: { storeId, periodYm } });
      await prisma.bankStatementLine.deleteMany({
        where: { storeId, periodYm },
      });
      await prisma.shift.updateMany({
        where: { storeId, closedAt: null },
        data: { closedAt: new Date(), closingCash: 0 },
      });
    }

    beforeEach(resetBookSide);
    afterAll(resetBookSide);

    it('tạo bút toán book-side cho một khoản phí NH chưa từng được ghi ở đâu, khớp dòng sao kê, và mở khóa được kỳ trước đó bị chặn', async () => {
      const day = periodYm + '-20';
      // Sao kê có một khoản phí NH -15.000đ chưa hề có chứng từ nào trong
      // app phía "book" ⇒ trước P2.2, kỳ này KHÔNG BAO GIỜ khoá được.
      const imp = await request(app.getHttpServer())
        .post('/reports/bank-recon/import')
        .set('Authorization', `Bearer ${token}`)
        .send({
          storeId,
          periodYm,
          csv: `date,amountVnd,memo\n${day},-15000,Phi NH`,
        })
        .expect(201);
      expect(imp.body.imported).toBe(1);

      const before = await request(app.getHttpServer())
        .get('/reports/bank-recon')
        .query({ storeId, periodYm })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(before.body.varianceVnd).not.toBe(0);
      expect(before.body.unmatchedStatementCount).toBe(1);
      const statementId = before.body.statements[0].id as string;
      expect(before.body.statements[0].matchedRef).toBeNull();

      // Chưa có bút toán book-side tương ứng ⇒ khoá kỳ bị chặn.
      await request(app.getHttpServer())
        .post('/reports/bank-recon/lock')
        .set('Authorization', `Bearer ${token}`)
        .send({ storeId, periodYm })
        .expect(400);

      const created = await request(app.getHttpServer())
        .post('/reports/bank-recon/create-entry')
        .set('Authorization', `Bearer ${token}`)
        .send({
          storeId,
          periodYm,
          statementId,
          categoryId: CATEGORY_ELECTRICITY, // direction 'out' — khớp amountVnd âm
          note: 'Phi NH tu doi chieu',
        })
        .expect(201);
      const voucherId = created.body.voucherId as string;
      expect(voucherId).toBeTruthy();

      const voucher = await prisma.cashVoucher.findUnique({
        where: { id: voucherId },
      });
      expect(voucher).toMatchObject({
        storeId,
        shiftId: null,
        channel: 'transfer',
        direction: 'out',
        amountVnd: 15_000,
      });

      const entry = await prisma.journalEntry.findUnique({
        where: {
          sourceType_sourceId: {
            sourceType: 'cash_voucher',
            sourceId: voucherId,
          },
        },
        include: { lines: true },
      });
      expect(entry).toBeTruthy();
      const debit = entry!.lines.reduce((s, l) => s + l.debitVnd, 0);
      const credit = entry!.lines.reduce((s, l) => s + l.creditVnd, 0);
      expect(debit).toBe(credit);
      expect(debit).toBe(15_000);
      // channel='transfer' ⇒ vế tiền đi qua 112, không phải 111.
      const creditLine = entry!.lines.find((l) => l.creditVnd > 0);
      expect(creditLine?.accountCode).toBe('112');

      const after = await request(app.getHttpServer())
        .get('/reports/bank-recon')
        .query({ storeId, periodYm })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(after.body.varianceVnd).toBe(0);
      expect(after.body.unmatchedStatementCount).toBe(0);
      expect(after.body.unmatchedBookCount).toBe(0);
      const matchedLine = after.body.statements.find(
        (s: { id: string }) => s.id === statementId,
      );
      expect(matchedLine.matchedRef).toBe(`voucher:${voucherId}`);

      // Giờ khoá được — trước đó bị chặn đúng vì thiếu bút toán book-side này.
      await request(app.getHttpServer())
        .post('/reports/bank-recon/lock')
        .set('Authorization', `Bearer ${token}`)
        .send({ storeId, periodYm })
        .expect(201);

      await prisma.bankReconLock.deleteMany({ where: { storeId, periodYm } });
    });

    it('từ chối: kỳ đã khoá, dòng sao kê không tồn tại/đã khớp, sai chiều danh mục', async () => {
      const day = periodYm + '-21';
      const imp = await request(app.getHttpServer())
        .post('/reports/bank-recon/import')
        .set('Authorization', `Bearer ${token}`)
        .send({
          storeId,
          periodYm,
          csv: `date,amountVnd,memo\n${day},-8000,Phi NH 2`,
        })
        .expect(201);
      expect(imp.body.imported).toBe(1);
      const summary = await request(app.getHttpServer())
        .get('/reports/bank-recon')
        .query({ storeId, periodYm })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      const statementId = summary.body.statements[0].id as string;

      // Sai chiều: dòng âm (out) nhưng danh mục thu (in) → 400.
      await request(app.getHttpServer())
        .post('/reports/bank-recon/create-entry')
        .set('Authorization', `Bearer ${token}`)
        .send({
          storeId,
          periodYm,
          statementId,
          categoryId: 'a1000000-0000-4000-8000-000000000001', // other_in — direction 'in'
        })
        .expect(400);

      // Dòng sao kê không tồn tại → 400.
      await request(app.getHttpServer())
        .post('/reports/bank-recon/create-entry')
        .set('Authorization', `Bearer ${token}`)
        .send({
          storeId,
          periodYm,
          statementId: randomUUID(),
          categoryId: CATEGORY_ELECTRICITY,
        })
        .expect(400);

      // Tạo hợp lệ một lần cho khớp, rồi thử lại trên dòng đã khớp → 400.
      await request(app.getHttpServer())
        .post('/reports/bank-recon/create-entry')
        .set('Authorization', `Bearer ${token}`)
        .send({ storeId, periodYm, statementId, categoryId: CATEGORY_ELECTRICITY })
        .expect(201);
      await request(app.getHttpServer())
        .post('/reports/bank-recon/create-entry')
        .set('Authorization', `Bearer ${token}`)
        .send({ storeId, periodYm, statementId, categoryId: CATEGORY_ELECTRICITY })
        .expect(400);

      // Kỳ đã khoá → mọi create-entry tiếp theo bị chặn.
      await request(app.getHttpServer())
        .post('/reports/bank-recon/auto-match')
        .set('Authorization', `Bearer ${token}`)
        .send({ storeId, periodYm })
        .expect(201);
      await request(app.getHttpServer())
        .post('/reports/bank-recon/lock')
        .set('Authorization', `Bearer ${token}`)
        .send({ storeId, periodYm })
        .expect(201);

      const day2 = periodYm + '-22';
      // Import bị chặn vì kỳ đã khoá — dùng insert thẳng Prisma cho statement
      // giả lập tình huống "dòng sao kê mới xuất hiện trong kỳ đã khoá" mà
      // không cần đi qua import (vốn tự chặn theo lock rồi).
      const lateStatement = await prisma.bankStatementLine.create({
        data: {
          id: randomUUID(),
          storeId,
          periodYm,
          bookedAt: new Date(`${day2}T12:00:00.000Z`),
          amountVnd: -5000,
          memo: 'late',
        },
      });
      await request(app.getHttpServer())
        .post('/reports/bank-recon/create-entry')
        .set('Authorization', `Bearer ${token}`)
        .send({
          storeId,
          periodYm,
          statementId: lateStatement.id,
          categoryId: CATEGORY_ELECTRICITY,
        })
        .expect(400);

      await prisma.bankReconLock.deleteMany({ where: { storeId, periodYm } });
    });

    it('cashier (không canLedger) bị chặn 403 bởi LedgerPermissionGuard', async () => {
      const day = periodYm + '-23';
      const imp = await request(app.getHttpServer())
        .post('/reports/bank-recon/import')
        .set('Authorization', `Bearer ${token}`)
        .send({
          storeId,
          periodYm,
          csv: `date,amountVnd,memo\n${day},-3000,Phi NH 3`,
        })
        .expect(201);
      expect(imp.body.imported).toBe(1);
      const summary = await request(app.getHttpServer())
        .get('/reports/bank-recon')
        .query({ storeId, periodYm })
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      const statementId = summary.body.statements[0].id as string;

      const cashierPhone = '0950400001';
      await request(app.getHttpServer())
        .post('/users')
        .set('Authorization', `Bearer ${token}`)
        .send({
          phone: cashierPhone,
          name: 'Thu ngan bank recon',
          password: '123456',
          role: 'cashier',
          storeIds: [storeId],
        })
        .expect(201);
      const cashierLogin = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ phone: cashierPhone, password: '123456' })
        .expect(201);
      const cashierToken = cashierLogin.body.accessToken as string;
      const cashierUserId = cashierLogin.body.user.id as string;

      await request(app.getHttpServer())
        .post('/reports/bank-recon/create-entry')
        .set('Authorization', `Bearer ${cashierToken}`)
        .send({
          storeId,
          periodYm,
          statementId,
          categoryId: CATEGORY_ELECTRICITY,
        })
        .expect(403);

      await prisma.userStore.deleteMany({ where: { userId: cashierUserId } });
      await prisma.user.deleteMany({ where: { id: cashierUserId } });
    });
  });
});
