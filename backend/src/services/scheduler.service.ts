import { BookingsService } from '../modules/bookings/bookings.service';
import { SpotsService } from '../modules/spots/spots.service';

/**
 * Background Job Scheduler for recurring ParkEase operations
 * - Auto-completes expired bookings every 5 minutes
 * - Restores parking spot availability
 * - Can be extended for notifications, reports, cleanups
 */
export class SchedulerService {
  private static intervals: Map<string, NodeJS.Timeout> = new Map();

  /**
   * Initialize all background jobs
   */
  static async initialize() {
    console.log('📅 Initializing background job scheduler...');

    // Sync expired bookings every 5 minutes
    this.startJob('syncExpiredBookings', 5 * 60 * 1000, async () => {
      try {
        await BookingsService.syncExpiredBookings();
        console.log('✅ [5min] Expired bookings synced and spots restored');
      } catch (err) {
        console.error('❌ [Scheduler] syncExpiredBookings failed:', err);
      }
    });

    // Optional: Deep cleanup every hour
    this.startJob('hourlyCleanup', 60 * 60 * 1000, async () => {
      try {
        // Can add deep DB cleanup, orphaned records, etc.
        console.log('✅ [60min] Hourly maintenance completed');
      } catch (err) {
        console.error('❌ [Scheduler] hourlyCleanup failed:', err);
      }
    });

    console.log('📅 Background scheduler initialized with 2 jobs');
  }

  /**
   * Register a background job that runs at a fixed interval
   */
  private static startJob(jobName: string, intervalMs: number, jobFn: () => Promise<void>) {
    if (this.intervals.has(jobName)) {
      console.warn(`⚠️  Job "${jobName}" already registered, skipping`);
      return;
    }

    const interval = setInterval(async () => {
      try {
        await jobFn();
      } catch (err) {
        console.error(`❌ Job "${jobName}" error:`, err);
      }
    }, intervalMs);

    this.intervals.set(jobName, interval);
    console.log(`📌 Job "${jobName}" scheduled every ${intervalMs / 1000}s`);
  }

  /**
   * Stop all background jobs (graceful shutdown)
   */
  static shutdown() {
    console.log('🛑 Shutting down background jobs...');
    for (const [jobName, interval] of this.intervals) {
      clearTimeout(interval);
      console.log(`  ✅ Stopped: ${jobName}`);
    }
    this.intervals.clear();
  }

  /**
   * Get current scheduled jobs (for monitoring)
   */
  static getJobs() {
    return Array.from(this.intervals.keys());
  }
}
