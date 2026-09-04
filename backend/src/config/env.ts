import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('5000'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().default('postgresql://postgres:postgres@localhost:5432/parkease?schema=public'),
  JWT_SECRET: z.string().default('parkease_super_secure_jwt_secret_key_2026_change_in_production'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  CHAPA_SECRET_KEY: z.string().default('CHASECK_TEST-sample_test_key'),
  CHAPA_WEBHOOK_SECRET: z.string().default('parkease_chapa_webhook_secret'),
  CORS_ORIGIN: z.string().default('*'),
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Invalid environment variables:', parsedEnv.error.format());
  process.exit(1);
}

export const env = parsedEnv.data;
