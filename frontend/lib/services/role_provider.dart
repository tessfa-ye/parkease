import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum for user roles
enum UserRole {
  driver('DRIVER'),
  attendant('ATTENDANT'),
  owner('OWNER');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'ATTENDANT':
        return UserRole.attendant;
      case 'OWNER':
      case 'HOST':
        return UserRole.owner;
      default:
        return UserRole.driver;
    }
  }
}

/// Manages user role state and persistence
class RoleProvider extends ChangeNotifier {
  static final RoleProvider instance = RoleProvider._();
  RoleProvider._();

  static const String _keyCurrentRole = 'current_user_role';

  UserRole _currentRole = UserRole.driver;
  List<UserRole> _availableRoles = [UserRole.driver];

  UserRole get currentRole => _currentRole;
  List<UserRole> get availableRoles => _availableRoles;

  bool get isDriver => _currentRole == UserRole.driver;
  bool get isAttendant => _currentRole == UserRole.attendant;
  bool get isOwner => _currentRole == UserRole.owner;

  /// Initialize role provider and restore saved role
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString(_keyCurrentRole);
    if (savedRole != null) {
      _currentRole = UserRole.fromString(savedRole);
    }
    notifyListeners();
  }

  /// Set available roles for the current user
  void setAvailableRoles(List<String> roles) {
    _availableRoles = roles.map((r) {
      // Normalize role strings
      final normalized = r.toUpperCase();
      if (normalized == 'USER' || normalized == 'DRIVER') {
        return UserRole.driver;
      } else if (normalized == 'ATTENDANT') {
        return UserRole.attendant;
      } else if (normalized == 'OWNER' || normalized == 'HOST') {
        return UserRole.owner;
      }
      return UserRole.driver;
    }).toList();
    
    // Remove duplicates
    _availableRoles = _availableRoles.toSet().toList();
    
    if (!_availableRoles.contains(_currentRole)) {
      _currentRole = _availableRoles.first;
    }
    notifyListeners();
  }

  /// Switch to a different role
  Future<void> switchRole(UserRole newRole) async {
    // For testing/sandbox, allow any role switch
    // In production with real backend, this check can be re-enabled
    _currentRole = newRole;

    // Persist the role preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentRole, newRole.value);

    notifyListeners();
  }

  /// Get all available role names
  List<String> getAvailableRoleNames() {
    return _availableRoles.map((r) => r.value).toList();
  }
}
