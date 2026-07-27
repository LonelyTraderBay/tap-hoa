/**
 * Locked local identity for folder/project `tap-hoa`.
 * Prevents pointing this API at another repo's Postgres/Supabase by mistake.
 *
 * Enforced when NODE_ENV is not `production` (unless TAP_HOA_SKIP_LOCAL_IDENTITY=1).
 * Production / commercial hosts skip this check — use real DATABASE_URL there.
 */

export const TAP_HOA_PROJECT_ID = 'tap-hoa';
export const TAP_HOA_DATABASE_NAME = 'tap_hoa';
export const TAP_HOA_LOCAL_DB_PORT = 54422;
export const TAP_HOA_LOCAL_API_PORT = 3040;
/** Default Nest listen port inside Docker prod image (host maps API_PORT). */
export const TAP_HOA_CONTAINER_API_PORT = 3000;

const LOCAL_HOSTS = new Set(['127.0.0.1', 'localhost', '::1']);

export type ParsedDatabaseUrl = {
  host: string;
  port: number;
  database: string;
  schema: string;
};

export function parseDatabaseUrl(url: string): ParsedDatabaseUrl {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    throw new Error(`[${TAP_HOA_PROJECT_ID}] DATABASE_URL is not a valid URL`);
  }
  if (parsed.protocol !== 'postgresql:' && parsed.protocol !== 'postgres:') {
    throw new Error(
      `[${TAP_HOA_PROJECT_ID}] DATABASE_URL must use postgresql:// (got ${parsed.protocol})`,
    );
  }
  const database = decodeURIComponent(parsed.pathname.replace(/^\//, '').split('/')[0] ?? '');
  const schema = parsed.searchParams.get('schema') ?? 'public';
  const port = parsed.port ? Number(parsed.port) : 5432;
  return {
    host: parsed.hostname.toLowerCase(),
    port,
    database,
    schema,
  };
}

export function assertTapHoaLocalIdentity(env: NodeJS.ProcessEnv = process.env): void {
  if (env.TAP_HOA_SKIP_LOCAL_IDENTITY === '1') {
    return;
  }
  if (env.NODE_ENV === 'production') {
    return;
  }

  const databaseUrl = env.DATABASE_URL?.trim();
  if (!databaseUrl) {
    throw new Error(
      `[${TAP_HOA_PROJECT_ID}] DATABASE_URL is required. Copy apps/api/.env.example → .env and run scripts/dev-up.ps1 (Supabase).`,
    );
  }

  const { host, port, database, schema } = parseDatabaseUrl(databaseUrl);

  if (!LOCAL_HOSTS.has(host)) {
    throw new Error(
      `[${TAP_HOA_PROJECT_ID}] Local DATABASE_URL host must be 127.0.0.1/localhost (got "${host}"). ` +
        `For remote/prod set NODE_ENV=production.`,
    );
  }

  if (port === 54322 || port === 5432) {
    throw new Error(
      `[${TAP_HOA_PROJECT_ID}] Refusing shared default Postgres port ${port}. ` +
        `This project locks Supabase DB to port ${TAP_HOA_LOCAL_DB_PORT} (project_id=${TAP_HOA_PROJECT_ID}). ` +
        `Clear shell DATABASE_URL if another project exported it.`,
    );
  }

  if (port !== TAP_HOA_LOCAL_DB_PORT) {
    throw new Error(
      `[${TAP_HOA_PROJECT_ID}] Local DATABASE_URL port must be ${TAP_HOA_LOCAL_DB_PORT} (got ${port}). ` +
        `See apps/api/supabase/config.toml (project_id=${TAP_HOA_PROJECT_ID}).`,
    );
  }

  if (database !== TAP_HOA_DATABASE_NAME) {
    throw new Error(
      `[${TAP_HOA_PROJECT_ID}] Local database name must be "${TAP_HOA_DATABASE_NAME}" (got "${database || '(empty)'}"). ` +
        `Do not use generic "postgres". Run scripts/ensure-tap-hoa-db.ps1 after supabase start.`,
    );
  }

  if (schema !== 'public') {
    throw new Error(
      `[${TAP_HOA_PROJECT_ID}] Local schema must be "public" (got "${schema}"). ` +
        `Another project's schema in DATABASE_URL will collide — clear shell env and use apps/api/.env.`,
    );
  }

  const portEnv = env.PORT?.trim();
  if (portEnv && Number(portEnv) !== TAP_HOA_LOCAL_API_PORT) {
    throw new Error(
      `[${TAP_HOA_PROJECT_ID}] Local PORT must be ${TAP_HOA_LOCAL_API_PORT} (got ${portEnv}). ` +
        `Keeps Nest off :3000 used by other apps.`,
    );
  }
}
