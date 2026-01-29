import 'package:freezed_annotation/freezed_annotation.dart';

part 'email_sync_settings_model.freezed.dart';
part 'email_sync_settings_model.g.dart';

/// Model representing email sync settings for a user
@freezed
abstract class EmailSyncSettingsModel with _$EmailSyncSettingsModel {
  const factory EmailSyncSettingsModel({
    /// Local database ID
    int? id,

    /// Connected Gmail email address
    String? gmailEmail,

    /// Whether email sync is enabled
    @Default(false) bool isEnabled,

    /// Timestamp of last successful sync
    DateTime? lastSyncTime,

    /// List of enabled bank domains to scan
    /// Stored as JSON array string in database
    @Default([]) List<String> enabledBanks,

    /// Total number of transactions imported from email
    @Default(0) int totalImported,

    /// Number of transactions pending review
    @Default(0) int pendingReview,

    /// Auto-sync frequency (default: every 24 hours)
    @Default(SyncFrequency.every24Hours) SyncFrequency syncFrequency,

    /// Timestamp when settings were created
    DateTime? createdAt,

    /// Timestamp when settings were last updated
    DateTime? updatedAt,
  }) = _EmailSyncSettingsModel;

  factory EmailSyncSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$EmailSyncSettingsModelFromJson(json);
}

/// Sync frequency options
enum SyncFrequency {
  /// Manual sync only - no background tasks
  manual,

  /// Sync every 12 hours
  every12Hours,

  /// Sync every 24 hours (recommended)
  every24Hours;

  /// Get frequency in hours (null for manual)
  int? get hours {
    switch (this) {
      case SyncFrequency.manual:
        return null;
      case SyncFrequency.every12Hours:
        return 12;
      case SyncFrequency.every24Hours:
        return 24;
    }
  }

  /// Get display label
  String get label {
    switch (this) {
      case SyncFrequency.manual:
        return 'Manual only';
      case SyncFrequency.every12Hours:
        return 'Every 12 hours';
      case SyncFrequency.every24Hours:
        return 'Every 24 hours (Recommended)';
    }
  }

  /// Get description
  String get description {
    switch (this) {
      case SyncFrequency.manual:
        return 'Only sync when you tap "Sync Now"';
      case SyncFrequency.every12Hours:
        return 'Sync twice a day, uses more battery';
      case SyncFrequency.every24Hours:
        return 'Sync once a day, battery friendly';
    }
  }

  /// Parse from string
  static SyncFrequency fromString(String value) {
    switch (value) {
      case 'manual':
        return SyncFrequency.manual;
      case 'every12Hours':
        return SyncFrequency.every12Hours;
      case 'every24Hours':
        return SyncFrequency.every24Hours;
      default:
        return SyncFrequency.every24Hours; // Default
    }
  }
}

/// Status of email sync connection
enum EmailSyncStatus {
  /// Not connected - user hasn't connected Gmail
  disconnected,

  /// Connected and active
  connected,

  /// Connected but sync is paused/disabled
  paused,

  /// Error state - needs re-authentication
  error,
}
