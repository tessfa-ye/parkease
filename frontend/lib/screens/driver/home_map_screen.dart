// This is a wrapper to avoid import conflicts
// Import and re-export the original HomeMapScreen
export '../home_map_screen.dart';

// Create an alias for consistency
import '../home_map_screen.dart';

class DriverHomeMapScreen extends HomeMapScreen {
  const DriverHomeMapScreen({super.key});
}
