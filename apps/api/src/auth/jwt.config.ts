const DEVELOPMENT_SECRET = 'dev-change-me';

export function getJwtSecret(): string {
  const configured = process.env.JWT_SECRET;
  if (configured) {
    return configured;
  }
  if (process.env.NODE_ENV === 'development') {
    console.warn(
      'JWT_SECRET is unset; using development-only fallback because NODE_ENV=development',
    );
    return DEVELOPMENT_SECRET;
  }
  throw new Error('JWT_SECRET is required');
}
