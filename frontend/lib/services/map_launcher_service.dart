import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class MapLauncherService {
  MapLauncherService._();

  /// Launch turn-by-turn driving directions in external Google Maps or Apple Maps app
  static Future<bool> launchDrivingDirections({
    required double latitude,
    required double longitude,
    String? destinationTitle,
    BuildContext? context,
  }) async {
    // 1. Google Maps turn-by-turn driving directions URL
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        final success = await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
        if (success) return true;
      }
    } catch (_) {}

    // 2. Fallback to OpenStreetMap Car Route
    final osmUrl = Uri.parse(
      'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=;$latitude%2C$longitude',
    );
    try {
      if (await canLaunchUrl(osmUrl)) {
        final success = await launchUrl(
          osmUrl,
          mode: LaunchMode.externalApplication,
        );
        if (success) return true;
      }
    } catch (_) {}

    // 3. Fallback to browser search
    final webUrl = Uri.parse('https://maps.google.com/?q=$latitude,$longitude');
    try {
      return await launchUrl(webUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map. Coordinates: $latitude, $longitude'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () => copyCoordinates(context, latitude, longitude),
            ),
          ),
        );
      }
      return false;
    }
  }

  /// Copy GPS coordinates to clipboard
  static void copyCoordinates(BuildContext context, double latitude, double longitude) {
    final text = '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coordinates copied: $text'),
        backgroundColor: AppColors.available,
      ),
    );
  }

  /// Show a modal bottom sheet with navigation options
  static void showDirectionsModal(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String title,
    String? address,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.navigation, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (address != null && address.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              address,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Option 1: Turn-by-Turn Driving (Google Maps)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_car, color: AppColors.primary, size: 28),
                  title: const Text('Google Maps Driving Navigation', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Live GPS route with turn-by-turn guidance'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchDrivingDirections(
                      latitude: latitude,
                      longitude: longitude,
                      destinationTitle: title,
                      context: context,
                    );
                  },
                ),
                const Divider(),

                // Option 2: Open in Web / OpenStreetMap
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.map_outlined, color: Color(0xFF10B981), size: 28),
                  title: const Text('OpenStreetMap Route', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Open routing in web browser'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final osmUrl = Uri.parse(
                      'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=;$latitude%2C$longitude',
                    );
                    await launchUrl(osmUrl, mode: LaunchMode.externalApplication);
                  },
                ),
                const Divider(),

                // Option 3: Copy GPS Coordinates
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.content_copy, color: AppColors.textSecondary, size: 26),
                  title: const Text('Copy GPS Coordinates', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    copyCoordinates(context, latitude, longitude);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
