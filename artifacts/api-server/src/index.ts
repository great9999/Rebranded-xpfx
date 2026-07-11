import 'express-async-errors';
import dotenv from 'dotenv';
dotenv.config();

import http from 'http';
import type { PrismaClient as PrismaClientType } from '@prisma/client';
import app from './app';

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

let prisma: PrismaClientType | null = null;

async function initDatabase() {
  if (!process.env.DATABASE_URL) {
    console.warn('[DB] DATABASE_URL not set — continuing without Prisma persistence');
    return null;
  }

  const { PrismaClient } = await import('@prisma/client');
  const client = new PrismaClient();
  await client.$connect();
  console.log('[DB] PostgreSQL connected via Prisma');
  return client;
}

async function bootstrap() {
  try {
    prisma = await initDatabase();

    server.listen(PORT, () => {
      console.log(`[SERVER] XpressPro FX API running on port ${PORT}`);
      console.log(`[SERVER] Environment: ${process.env.NODE_ENV}`);
      console.log(`[SERVER] Health: http://localhost:${PORT}/healthz`);
    });
  } catch (error) {
    console.error('[SERVER] Failed to start:', error);
    await prisma?.$disconnect();
    process.exit(1);
  }
}

process.on('SIGTERM', async () => {
  console.log('[SERVER] SIGTERM received — shutting down gracefully');
  server.close(async () => {
    await prisma?.$disconnect();
    console.log('[SERVER] Shutdown complete');
    process.exit(0);
  });
});

process.on('SIGINT', async () => {
  console.log('[SERVER] SIGINT received — shutting down gracefully');
  server.close(async () => {
    await prisma?.$disconnect();
    process.exit(0);
  });
});

bootstrap();
