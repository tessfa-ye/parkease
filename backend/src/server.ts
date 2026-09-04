import { createApp } from './app';
import { env } from './config/env';

const app = createApp();

const server = app.listen(env.PORT, () => {
  console.log(`
  🚀 ========================================== 🚀
     ParkEase Backend REST API Started!
     - Port:        ${env.PORT}
     - Environment: ${env.NODE_ENV}
     - Health:      http://localhost:${env.PORT}/api/health
     - Spots API:   http://localhost:${env.PORT}/api/spots
     - Chapa Ready: ${env.CHAPA_SECRET_KEY.startsWith('CHASECK_TEST') ? 'TEST MODE 🟢' : 'LIVE 🔴'}
  🚀 ========================================== 🚀
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
