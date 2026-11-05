import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';

/// Reactive in-memory and persistent store for user parking bookings / trips.
/// Ensures newly created bookings immediately appear in TripHistoryScreen
/// and stay persisted across screen transitions and restarts.
class BookingStore extends ChangeNotifier {
  BookingStore._();
  static final BookingStore instance = BookingStore._();

  static const String _keyBookings = 'user_bookings_cache';

  final List<Booking> _bookings = [
    // Pre-populate with realistic seed bookings
    ...Booking.sampleBookings,
  ];

  bool _isInitialized = false;

  List<Booking> get bookings => List.unmodifiable(_bookings);

  /// Grace period after parking time expires before auto-checkout (15 minutes).
  static const Duration gracePeriod = Duration(minutes: 15);

  List<Booking> get activeBookings {
    checkAndAutoCompleteExpired(notify: false);
    return _bookings.where((b) => b.status == BookingStatus.active).toList();
  }

  List<Booking> get completedBookings {
    checkAndAutoCompleteExpired(notify: false);
    return _bookings.where((b) => b.status == BookingStatus.completed).toList();
  }

  List<Booking> get cancelledBookings =>
      _bookings.where((b) => b.status == BookingStatus.cancelled).toList();

  /// Automatically completes any active booking that has been expired
  /// for longer than the 15-minute grace period.
  bool checkAndAutoCompleteExpired({bool notify = true}) {
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _bookings.length; i++) {
      final b = _bookings[i];
      if (b.status == BookingStatus.active) {
        // If parking ended and grace period has also passed
        if (now.isAfter(b.endTime.add(gracePeriod))) {
          _bookings[i] = b.copyWith(status: BookingStatus.completed);
          changed = true;
        }
      }
    }

    if (changed) {
      _saveToDisk();
      if (notify) notifyListeners();
    }
    return changed;
  }

  /// Initialize and restore stored bookings from SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    await _loadFromDisk();
    _isInitialized = true;
  }

  /// Force a fresh reload from SharedPreferences (bypasses the init guard).
  /// Use this when you need guaranteed up-to-date data, e.g. in the scanner.
  Future<void> forceReload() async {
    await _loadFromDisk();
    _isInitialized = true;
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_keyBookings);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final b = Booking.fromJson(item);
            final idx = _bookings.indexWhere((existing) => existing.id == b.id);
            if (idx >= 0) {
              _bookings[idx] = b;
            } else {
              _bookings.insert(0, b);
            }
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Add a newly created booking
  void addBooking(Booking booking) {
    final idx = _bookings.indexWhere((b) => b.id == booking.id);
    if (idx >= 0) {
      _bookings[idx] = booking;
    } else {
      _bookings.insert(0, booking);
    }
    _saveToDisk();
    notifyListeners();
  }

  /// Cancel an active booking 
  void cancelBooking(String bookingId) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx >= 0) {
      _bookings[idx] = _bookings[idx].copyWith(status: BookingStatus.cancelled);
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Mark an active booking as completed
  void completeBooking(String bookingId) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx >= 0) {
      _bookings[idx] = _bookings[idx].copyWith(status: BookingStatus.completed);
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Extend an active booking with more time and updated cost
  void extendBooking(String bookingId, int additionalHours, double additionalAmount) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx >= 0) {
      final current = _bookings[idx];
      final now = DateTime.now();
      // If the booking is already expired, extend from right now!
      // Otherwise extend from current endTime.
      final baseTime = current.endTime.isBefore(now) ? now : current.endTime;
      final newEndTime = baseTime.add(Duration(hours: additionalHours));
      
      _bookings[idx] = current.copyWith(
        endTime: newEndTime,
        durationHours: current.durationHours + additionalHours,
        totalPriceETB: current.totalPriceETB + additionalAmount,
      );
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Start a scheduled booking immediately when user arrives ahead of schedule
  void startBookingNow(String bookingId) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx >= 0) {
      final current = _bookings[idx];
      final now = DateTime.now();
      final newEndTime = now.add(Duration(hours: current.durationHours));
      _bookings[idx] = current.copyWith(
        startTime: now,
        endTime: newEndTime,
      );
      _saveToDisk();
      notifyListeners();
    }
  }

  /// Synchronize with bookings fetched from backend API
  void mergeFromApi(List<Booking> apiBookings) {
    bool changed = false;
    for (final apiBooking in apiBookings) {
      final idx = _bookings.indexWhere((b) => b.id == apiBooking.id);
      if (idx >= 0) {
        if (_bookings[idx].status != apiBooking.status) {
          _bookings[idx] = apiBooking;
          changed = true;
        }
      } else {
        _bookings.insert(0, apiBooking);
        changed = true;
      }
    }
    if (changed) {
      _saveToDisk();
      notifyListeners();
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _bookings.map((b) => b.toJson()).toList();
      await prefs.setString(_keyBookings, jsonEncode(jsonList));
    } catch (_) {}
  }
  /// Return active bookings as a Future for UI consumption
  Future<List<Booking>> getActiveBookings() async {
    // Ensure the store is initialized (loads from SharedPreferences)
    await init();
    return activeBookings;
  }
}

