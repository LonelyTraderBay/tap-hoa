import {
  TAP_HOA_LOCAL_API_PORT,
  TAP_HOA_LOCAL_DB_PORT,
  assertTapHoaLocalIdentity,
  parseDatabaseUrl,
} from './tap-hoa.identity';

const goodUrl = `postgresql://postgres:postgres@127.0.0.1:${TAP_HOA_LOCAL_DB_PORT}/tap_hoa?schema=public`;

describe('tap-hoa.identity', () => {
  it('parses DATABASE_URL', () => {
    expect(parseDatabaseUrl(goodUrl)).toEqual({
      host: '127.0.0.1',
      port: TAP_HOA_LOCAL_DB_PORT,
      database: 'tap_hoa',
      schema: 'public',
    });
  });

  it('allows locked local URL', () => {
    expect(() =>
      assertTapHoaLocalIdentity({
        DATABASE_URL: goodUrl,
        PORT: String(TAP_HOA_LOCAL_API_PORT),
      }),
    ).not.toThrow();
  });

  it('skips in production', () => {
    expect(() =>
      assertTapHoaLocalIdentity({
        NODE_ENV: 'production',
        DATABASE_URL: 'postgresql://u:p@db.example:5432/anything',
      }),
    ).not.toThrow();
  });

  it('skips when TAP_HOA_SKIP_LOCAL_IDENTITY=1', () => {
    expect(() =>
      assertTapHoaLocalIdentity({
        TAP_HOA_SKIP_LOCAL_IDENTITY: '1',
        DATABASE_URL: 'postgresql://postgres:postgres@127.0.0.1:54322/postgres',
      }),
    ).not.toThrow();
  });

  it('rejects default Supabase port 54322', () => {
    expect(() =>
      assertTapHoaLocalIdentity({
        DATABASE_URL:
          'postgresql://postgres:postgres@127.0.0.1:54322/postgres?schema=taskd_period_unlock',
      }),
    ).toThrow(/54422|54322|Refusing shared/);
  });

  it('rejects generic database name postgres', () => {
    expect(() =>
      assertTapHoaLocalIdentity({
        DATABASE_URL: `postgresql://postgres:postgres@127.0.0.1:${TAP_HOA_LOCAL_DB_PORT}/postgres?schema=public`,
      }),
    ).toThrow(/tap_hoa/);
  });

  it('rejects foreign schema', () => {
    expect(() =>
      assertTapHoaLocalIdentity({
        DATABASE_URL: `postgresql://postgres:postgres@127.0.0.1:${TAP_HOA_LOCAL_DB_PORT}/tap_hoa?schema=taskd_period_unlock`,
      }),
    ).toThrow(/public/);
  });

  it('rejects wrong Nest PORT', () => {
    expect(() =>
      assertTapHoaLocalIdentity({
        DATABASE_URL: goodUrl,
        PORT: '3000',
      }),
    ).toThrow(new RegExp(String(TAP_HOA_LOCAL_API_PORT)));
  });
});
