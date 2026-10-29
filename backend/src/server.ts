import { createApp } from './app';
import { env } from './config/env';
import { SchedulerService } from './services/scheduler.service';

const app = createApp();

const server = app.listen(env.PORT, async () => {
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

  // Initialize background job scheduler
  await SchedulerService.initialize();
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  SchedulerService.shutdown();
  server.close(() => {
    console.log('HTTP server closed');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  SchedulerService.shutdown();
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});
