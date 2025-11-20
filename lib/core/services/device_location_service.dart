import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:bexly/core/utils/logger.dart';

/// Service to detect device's current country/location
/// Uses multiple sources: SIM card → Timezone → Locale
class DeviceLocationService {
  static const platform = MethodChannel('com.joy.bexly/device_location');

  /// Get country code from device (SIM → Timezone → Locale)
  static Future<String> getCountryCode() async {
    // Try 1: Get from SIM card (most accurate)
    try {
      final simCountry = await platform.invokeMethod<String>('getSimCountryCode');
      if (simCountry != null && simCountry.isNotEmpty) {
        Log.d('Country from SIM: $simCountry', label: 'location');
        return simCountry.toUpperCase();
      }
    } catch (e) {
      Log.w('Failed to get SIM country: $e', label: 'location');
    }

    // Try 2: Get from timezone
    try {
      final countryCode = _getCountryFromTimezone();
      if (countryCode != null) {
        Log.d('Country from timezone: $countryCode', label: 'location');
        return countryCode;
      }
    } catch (e) {
      Log.w('Failed to get timezone country: $e', label: 'location');
    }

    // Try 3: Get from locale
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode?.toUpperCase();
      if (countryCode != null && countryCode.isNotEmpty) {
        Log.d('Country from locale: $countryCode', label: 'location');
        return countryCode;
      }
    } catch (e) {
      Log.w('Failed to get locale country: $e', label: 'location');
    }

    // Default: US
    Log.d('Using default country: US', label: 'location');
    return 'US';
  }

  /// Map timezone to country code
  static String? _getCountryFromTimezone() {
    final timeZoneName = DateTime.now().timeZoneName;

    // Map timezone names/abbreviations to country codes
    const timezoneToCountry = {
      // IANA timezone IDs (full names) - most common
      'Asia/Ho_Chi_Minh': 'VN',
      'Asia/Saigon': 'VN',
      'Asia/Bangkok': 'TH',  // Thailand, not Vietnam
      'Asia/Jakarta': 'ID',
      'Asia/Singapore': 'SG',
      'Asia/Kuala_Lumpur': 'MY',
      'Asia/Manila': 'PH',
      'Asia/Tokyo': 'JP',
      'Asia/Seoul': 'KR',
      'Asia/Shanghai': 'CN',
      'Europe/London': 'GB',
      'America/New_York': 'US',
      'America/Los_Angeles': 'US',
      'Australia/Sydney': 'AU',

      // Timezone abbreviations (fallback for older Android versions)
      'ICT': 'VN',  // Indochina Time - prefer Vietnam
      'WIB': 'ID',
      'WITA': 'ID',
      'WIT': 'ID',
      'SGT': 'SG',
      'MYT': 'MY',
      'PHT': 'PH',
      'JST': 'JP',
      'KST': 'KR',
      'CST': 'CN',
      'GMT': 'GB',
      'BST': 'GB',
      'EST': 'US',
      'PST': 'US',
      'AEST': 'AU',
    };

    return timezoneToCountry[timeZoneName];
  }
}
