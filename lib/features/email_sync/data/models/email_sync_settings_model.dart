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

    /// Timestamp when settings were created
    DateTime? createdAt,

    /// Timestamp when settings were last updated
    DateTime? updatedAt,
  }) = _EmailSyncSettingsModel;

  factory EmailSyncSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$EmailSyncSettingsModelFromJson(json);
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
