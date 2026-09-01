import 'dart:ui';

/// Utility class for locale-aware currency, country, and region formatting.
/// Supports global use — auto-detects country from device locale.
class LocaleUtils {
  /// Returns the currency symbol for a given ISO country code.
  static String currencySymbol(String countryCode) {
    const map = {
      'ET': 'ETB',
      'US': 'USD',
      'GB': 'GBP',
      'EU': 'EUR',
      'KE': 'KES',
      'NG': 'NGN',
      'ZA': 'ZAR',
      'GH': 'GHS',
      'UG': 'UGX',
      'TZ': 'TZS',
      'RW': 'RWF',
      'EG': 'EGP',
      'MA': 'MAD',
      'TN': 'TND',
      'DZ': 'DZD',
      'IN': 'INR',
      'CN': 'CNY',
      'JP': 'JPY',
      'AE': 'AED',
      'SA': 'SAR',
      'AU': 'AUD',
      'CA': 'CAD',
    };
    return map[countryCode.toUpperCase()] ?? 'USD';
  }

  /// Returns the currency display symbol (e.g. Br, \$, £).
  static String currencyDisplaySymbol(String countryCode) {
    const map = {
      'ET': 'Br',
      'US': '\$',
      'GB': '£',
      'KE': 'KSh',
      'NG': '₦',
      'ZA': 'R',
      'GH': '₵',
      'EG': 'E£',
      'IN': '₹',
      'CN': '¥',
      'JP': '¥',
      'AE': 'AED',
      'SA': 'SAR',
      'AU': 'A\$',
      'CA': 'C\$',
    };
    return map[countryCode.toUpperCase()] ?? '\$';
  }

  /// Returns the device's current country code from locale (e.g. 'ET', 'US').
  static String get deviceCountryCode {
    final locale = PlatformDispatcher.instance.locale;
    return locale.countryCode ?? 'ET'; // Default to Ethiopia
  }

  /// Formats a price with the correct currency symbol for a country.
  static String formatPrice(double amount, String countryCode) {
    final symbol = currencyDisplaySymbol(countryCode);
    if (amount == amount.roundToDouble()) {
      return '$symbol ${amount.toInt()}';
    }
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  /// Returns the distance unit for a country (miles or km).
  static String distanceUnit(String countryCode) {
    const milesCountries = {'US', 'GB', 'LR', 'MM'};
    return milesCountries.contains(countryCode.toUpperCase()) ? 'mi' : 'km';
  }

  /// Returns a country flag emoji from its ISO code.
  static String flagEmoji(String countryCode) {
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '🌍';
    final first = 0x1F1E0 + code.codeUnitAt(0) - 0x41;
    final second = 0x1F1E0 + code.codeUnitAt(1) - 0x41;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
