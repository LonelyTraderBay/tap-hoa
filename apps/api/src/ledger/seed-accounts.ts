import { AccountType, PrismaClient } from '@prisma/client';

/** Seed chart of accounts (idempotent upserts). */
export async function seedChartOfAccounts(prisma: PrismaClient) {
  const accounts: { code: string; name: string; type: AccountType }[] = [
    { code: '111', name: 'Tiền mặt', type: AccountType.asset },
    { code: '112', name: 'Tiền gửi ngân hàng', type: AccountType.asset },
    { code: '131', name: 'Phải thu khách hàng', type: AccountType.asset },
    { code: '1331', name: 'GTGT được khấu trừ', type: AccountType.asset },
    { code: '151', name: 'Hàng đi đường', type: AccountType.asset },
    { code: '156', name: 'Hàng tồn kho', type: AccountType.asset },
    { code: '331', name: 'Phải trả nhà cung cấp', type: AccountType.liability },
    { code: '3331', name: 'GTGT phải nộp', type: AccountType.liability },
    { code: '511', name: 'Doanh thu bán hàng', type: AccountType.revenue },
    { code: '632', name: 'Giá vốn hàng bán', type: AccountType.expense },
    { code: '642', name: 'Chi phí quản lý', type: AccountType.expense },
    { code: '711', name: 'Thu nhập khác', type: AccountType.revenue },
  ];
  for (const a of accounts) {
    await prisma.account.upsert({
      where: { code: a.code },
      update: { name: a.name, type: a.type, active: true },
      create: a,
    });
  }
}
