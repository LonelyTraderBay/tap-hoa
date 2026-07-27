import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { seedChartOfAccounts } from '../src/ledger/seed-accounts';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Wave C AP recon e2e', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;
  let storeId: string;
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
    const now = new Date();
    const ict = new Date(now.getTime() + 7 * 3600_000);
    periodYm = `${ict.getUTCFullYear()}-${String(ict.getUTCMonth() + 1).padStart(2, '0')}`;
  });

  afterAll(async () => {
    await app.close();
  });

  it('imports supplier statement, matches payable/payment, unmatches, rematches, and locks', async () => {
    const supplier = await prisma.supplier.create({
      data: {
        id: randomUUID(),
        name: `AP Recon ${randomUUID().slice(0, 8)}`,
      },
    });
    const payableId = randomUUID();
    const paymentId = randomUUID();
    const day = `${periodYm}-15`;
    const at = new Date(`${day}T05:00:00.000Z`);

    await prisma.apReconLock.deleteMany({
      where: { storeId, supplierId: supplier.id, periodYm },
    });
    await prisma.apStatementLine.deleteMany({
      where: { storeId, supplierId: supplier.id, periodYm },
    });
    await prisma.supplierPayable.create({
      data: {
        id: payableId,
        supplierId: supplier.id,
        storeId,
        amountVnd: 120_000,
        balanceVnd: 80_000,
        clientCreatedAt: at,
      },
    });
    await prisma.supplierPayment.create({
      data: {
        id: paymentId,
        supplierId: supplier.id,
        storeId,
        amountVnd: 40_000,
        channel: 'transfer',
        recordedById: userId,
        clientCreatedAt: at,
      },
    });

    const csv =
      `date,amountVnd,memo\n` +
      `${day},120000,${payableId.slice(0, 8)}\n` +
      `${day},-40000,${paymentId.slice(0, 8)}`;
    const imp = await request(app.getHttpServer())
      .post('/reports/ap-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        supplierId: supplier.id,
        periodYm,
        csv,
      })
      .expect(201);
    expect(imp.body.imported).toBe(2);

    const duplicate = await request(app.getHttpServer())
      .post('/reports/ap-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        supplierId: supplier.id,
        periodYm,
        csv,
      })
      .expect(201);
    expect(duplicate.body.imported).toBe(0);
    expect(duplicate.body.skippedDuplicates).toBe(2);

    const summary = await request(app.getHttpServer())
      .get('/reports/ap-recon')
      .query({ storeId, supplierId: supplier.id, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(summary.body.bookTotalVnd).toBe(80_000);
    expect(summary.body.statementTotalVnd).toBe(80_000);
    expect(summary.body.varianceVnd).toBe(0);
    expect(summary.body.suggestedMatchCount).toBe(2);
    expect(summary.body.statements.every((s: { matchedRef: string | null }) => s.matchedRef == null)).toBe(true);

    const again = await request(app.getHttpServer())
      .get('/reports/ap-recon')
      .query({ storeId, supplierId: supplier.id, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(again.body.statements.every((s: { matchedRef: string | null }) => s.matchedRef == null)).toBe(true);

    await request(app.getHttpServer())
      .post('/reports/ap-recon/auto-match')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId, supplierId: supplier.id, periodYm })
      .expect(201);

    const matched = await request(app.getHttpServer())
      .get('/reports/ap-recon')
      .query({ storeId, supplierId: supplier.id, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(matched.body.matchedCount).toBe(2);

    const firstStatement = matched.body.statements[0];
    await request(app.getHttpServer())
      .post('/reports/ap-recon/unmatch')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        supplierId: supplier.id,
        periodYm,
        statementId: firstStatement.id,
        matchVersion: firstStatement.matchVersion,
      })
      .expect(201);

    const suggested = await request(app.getHttpServer())
      .get('/reports/ap-recon')
      .query({ storeId, supplierId: supplier.id, periodYm })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const rematch = suggested.body.matched.find(
      (m: { statementId: string; suggested: boolean }) =>
        m.statementId === firstStatement.id && m.suggested,
    );
    expect(rematch).toBeDefined();
    await request(app.getHttpServer())
      .post('/reports/ap-recon/match')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        supplierId: supplier.id,
        periodYm,
        statementId: firstStatement.id,
        bookRef: rematch.bookRef,
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/reports/ap-recon/lock')
      .set('Authorization', `Bearer ${token}`)
      .send({ storeId, supplierId: supplier.id, periodYm })
      .expect(201);

    await request(app.getHttpServer())
      .post('/reports/ap-recon/import')
      .set('Authorization', `Bearer ${token}`)
      .send({
        storeId,
        supplierId: supplier.id,
        periodYm,
        csv: `${day},1000,x`,
      })
      .expect(400);

    // Dọn `SupplierPayment`/`SupplierPayable` (tạo thẳng qua prisma, channel
    // 'transfer', clientCreatedAt = ngày 15 tháng hiện tại) — nếu không,
    // `reports.service.ts::loadBankBook` (dùng chung storeId CH1 + khoảng
    // ngày cả tháng) sẽ cộng dư -40.000đ vào `bookTotalVnd` của bất kỳ spec
    // nào chạy sau trong cùng lượt `--runInBand` mà đọc sổ quỹ NH của CH1
    // trong tháng hiện tại (vd. bank-recon.e2e-spec.ts).
    await prisma.supplierPayment.deleteMany({
      where: { supplierId: supplier.id },
    });
    await prisma.supplierPayable.deleteMany({
      where: { supplierId: supplier.id },
    });
  });
});
