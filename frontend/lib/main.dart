import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'l10n/app_strings.dart';

import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import '../services/auth_service.dart';
import '../services/booking_store.dart';
import '../services/vehicle_store.dart';
import '../services/host_space_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Android Google Maps to use native SurfaceView (Hybrid Composition).
  // This eliminates the "updateAcquireFence: Did not find frame" SurfaceTexture buffer queue spam.
  final GoogleMapsFlutterPlatform mapsPlatform = GoogleMapsFlutterPlatform.instance;
  if (mapsPlatform is GoogleMapsFlutterAndroid) {
    mapsPlatform.useAndroidViewSurface = true;
    try {
      await mapsPlatform.initializeWithRenderer(AndroidMapRenderer.latest);
    } catch (_) {}
  }

  await AuthService.instance.init();
  await BookingStore.instance.init();
  await VehicleStore.instance.init();
  await HostSpaceStore.instance.init();
  runApp(const ParkEaseApp());
}

class ParkEaseApp extends StatelessWidget {
  const ParkEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: LanguageController.instance.locale,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('am', 'ET'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const OnboardingScreen(),
        );
      },
    );
  }
}
