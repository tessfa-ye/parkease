// This is a wrapper to avoid import conflicts
// Import and re-export the original TripHistoryScreen
export '../trip_history_screen.dart';

// Create an alias for consistency
import '../trip_history_screen.dart';

class DriverTripHistoryScreen extends TripHistoryScreen {
  const DriverTripHistoryScreen({super.key});
}
