// One-shot production owner account bootstrap. Requires OWNER_PHONE and OWNER_PASSWORD.
import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

function requireEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

async function main() {
  const phone = requireEnv('OWNER_PHONE');
  const password = requireEnv('OWNER_PASSWORD');

  if (password === '123456') {
    throw new Error('OWNER_PASSWORD must not use the seed password 123456');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const owner = await prisma.user.upsert({
    where: { phone },
    update: {
      passwordHash,
      role: Role.owner,
      canLedger: true,
      canEinvoice: true,
      active: true,
    },
    create: {
      phone,
      name: 'Chu quan',
      passwordHash,
      role: Role.owner,
      canLedger: true,
      canEinvoice: true,
      active: true,
    },
  });

  console.log({
    owner: owner.phone,
    role: owner.role,
    active: owner.active,
  });
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
