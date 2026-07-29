// apps/api/prisma.config.ts
// Prisma 7: CLI config replaces datasource.url in schema.prisma (removed) and
// the "prisma"."seed" block in package.json (also removed). No `dotenv/config`
// import here: this project never relied on a .env FILE being auto-loaded by
// the Prisma CLI — DATABASE_URL is always injected as a real process env var
// (Docker ENV/`-e`, CI `env:`, or the shell), so there is nothing for dotenv
// to load and adding the dependency would be pure scope creep.
import { defineConfig, env } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    seed: 'ts-node prisma/seed.ts',
  },
  datasource: {
    url: env('DATABASE_URL'),
  },
});
