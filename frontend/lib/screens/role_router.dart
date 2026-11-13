import 'package:flutter/material.dart';
import '../services/role_provider.dart';
import 'driver/driver_home_screen.dart';
import 'attendant/attendant_home_screen.dart';
import 'owner/owner_home_screen.dart';

/// Routes to the appropriate home screen based on the user's current role
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoleProvider.instance,
      builder: (context, _) {
        switch (RoleProvider.instance.currentRole) {
          case UserRole.driver:
            return const DriverHomeScreen();
          case UserRole.attendant:
            return const AttendantHomeScreen();
          case UserRole.owner:
            return const OwnerHomeScreen();
        }
      },
    );
  }
}
