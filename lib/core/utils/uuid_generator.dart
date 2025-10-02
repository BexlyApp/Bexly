import 'package:uuid/uuid.dart';

/// UUID Generator utility using UUID v7 (timestamp-based)
///
/// UUID v7 benefits:
/// - Sortable by creation time (timestamp prefix)
/// - Better database performance (sequential)
/// - Globally unique
/// - Compatible with all UUID systems
class UuidGenerator {
  static const Uuid _uuid = Uuid();

  /// Generate a new UUID v7 (timestamp-based)
  ///
  /// Format: xxxxxxxx-xxxx-7xxx-xxxx-xxxxxxxxxxxx
  /// - First 48 bits: Unix timestamp in milliseconds
  /// - Remaining bits: random
  static String generate() {
    return _uuid.v7();
  }

  /// Generate a new UUID v7 with custom timestamp
  static String generateWithTimestamp(DateTime timestamp) {
    return _uuid.v7(config: V7Options(timestamp));
  }

  /// Validate if a string is a valid UUID
  static bool isValid(String? uuid) {
    if (uuid == null || uuid.isEmpty) return false;

    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    return uuidRegex.hasMatch(uuid);
  }

  /// Extract timestamp from UUID v7
  static DateTime? getTimestamp(String uuid) {
    if (!isValid(uuid)) return null;

    try {
      // UUID v7 format: timestamp (48 bits) + version (4 bits) + random
      final hex = uuid.replaceAll('-', '');
      final timestampHex = hex.substring(0, 12); // First 48 bits = 12 hex chars
      final timestampMs = int.parse(timestampHex, radix: 16);

      return DateTime.fromMillisecondsSinceEpoch(timestampMs);
    } catch (e) {
      return null;
    }
  }
}