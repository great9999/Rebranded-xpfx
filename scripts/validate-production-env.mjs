function validateProductionEnvironment(env = process.env) {
  const errors = [];

  if (env.NODE_ENV === 'production') {
    if (!env.SESSION_SECRET || env.SESSION_SECRET.trim().length < 32) {
      errors.push('SESSION_SECRET must be set to a strong value in production.');
    }

    if (!env.WALLET_ENCRYPTION_KEY || env.WALLET_ENCRYPTION_KEY.trim().length !== 64) {
      errors.push('WALLET_ENCRYPTION_KEY must be set to a 64-character hex key in production.');
    }

    if (!env.DATABASE_URL || !env.DATABASE_URL.includes('postgres')) {
      errors.push('DATABASE_URL must be set to a PostgreSQL connection string in production.');
    }
  }

  if (errors.length > 0) {
    throw new Error(errors.join(' '));
  }

  return true;
}

export { validateProductionEnvironment };
