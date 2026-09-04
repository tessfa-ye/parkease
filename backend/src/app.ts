import express from 'express';
import cors from 'cors';
import { env } from './config/env';
import { errorHandler } from './middlewares/error.middleware';
import { authRoutes } from './modules/auth/auth.routes';
import { spotsRoutes } from './modules/spots/spots.routes';
import { bookingsRoutes } from './modules/bookings/bookings.routes';
import { paymentsRoutes } from './modules/payments/payments.routes';
import { hostsRoutes } from './modules/hosts/hosts.routes';

export const createApp = (): express.Application => {
  const app = express();

  // Middleware pipeline
  app.use(
    cors({
      origin: env.CORS_ORIGIN,
      credentials: true,
    })
  );
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // Health Check Endpoint
  app.get('/api/health', (req, res) => {
    res.status(200).json({
      status: 'ok',
      service: 'ParkEase Backend API',
      timestamp: new Date().toISOString(),
      environment: env.NODE_ENV,
    });
  });

  // Feature Routes
  app.use('/api/auth', authRoutes);
  app.use('/api/spots', spotsRoutes);
  app.use('/api/bookings', bookingsRoutes);
  app.use('/api/payments', paymentsRoutes);
  app.use('/api/hosts', hostsRoutes);

  // Global Error Handler
  app.use(errorHandler);

  return app;
};
