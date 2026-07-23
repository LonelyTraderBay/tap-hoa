// apps/api/prisma/seed.ts
import { CashDirection, PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash('123456', 10);
  const s1 = await prisma.store.upsert({
    where: { code: 'CH1' },
    update: {},
    create: { code: 'CH1', name: 'Cua hang 1' },
  });
  const s2 = await prisma.store.upsert({
    where: { code: 'CH2' },
    update: {},
    create: { code: 'CH2', name: 'Cua hang 2' },
  });
  const cashCategories = [
    {
      id: 'a1000000-0000-4000-8000-000000000001',
      code: 'other_in',
      name: 'Thu khác',
      direction: CashDirection.in,
      sortOrder: 10,
    },
    {
      id: 'a1000000-0000-4000-8000-000000000002',
      code: 'electricity',
      name: 'Điện',
      direction: CashDirection.out,
      sortOrder: 20,
    },
    {
      id: 'a1000000-0000-4000-8000-000000000003',
      code: 'rent',
      name: 'Thuê mặt bằng',
      direction: CashDirection.out,
      sortOrder: 30,
    },
    {
      id: 'a1000000-0000-4000-8000-000000000004',
      code: 'salary_advance',
      name: 'Ứng lương',
      direction: CashDirection.out,
      sortOrder: 40,
    },
    {
      id: 'a1000000-0000-4000-8000-000000000005',
      code: 'other_out',
      name: 'Chi khác',
      direction: CashDirection.out,
      sortOrder: 50,
    },
  ];
  for (const category of cashCategories) {
    await prisma.cashCategory.upsert({
      where: { id: category.id },
      update: {
        code: category.code,
        name: category.name,
        direction: category.direction,
        sortOrder: category.sortOrder,
      },
      create: category,
    });
  }
  const owner = await prisma.user.upsert({
    where: { phone: '0900000001' },
    update: {},
    create: {
      phone: '0900000001',
      name: 'Chu quan',
      passwordHash,
      role: Role.owner,
      stores: { create: [{ storeId: s1.id }, { storeId: s2.id }] },
    },
  });
  const p1 = await prisma.product.upsert({
    where: { sku: 'STING-330' },
    update: {},
    create: {
      sku: 'STING-330',
      barcode: '8934588012345',
      name: 'Sting do 330ml',
      unit: 'chai',
      basePriceVnd: 10000,
      costVnd: 7500,
    },
  });
  for (const storeId of [s1.id, s2.id]) {
    await prisma.productStoreStock.upsert({
      where: { productId_storeId: { productId: p1.id, storeId } },
      update: { qty: 100 },
      create: { productId: p1.id, storeId, qty: 100, minQty: 10 },
    });
  }
  console.log({
    owner: owner.phone,
    stores: [s1.code, s2.code],
    cashCategories: cashCategories.map((c) => c.code),
  });
}

main().finally(() => prisma.$disconnect());
