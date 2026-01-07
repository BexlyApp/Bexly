import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_auth_service.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_api_service.dart';
import 'package:bexly/features/email_sync/data/models/email_sync_settings_model.dart';

/// Provider for GmailApiService (shared singleton)
final _gmailApiServiceInstance = GmailApiService();

/// Provider for GmailApiService
final gmailApiServiceProvider = Provider<GmailApiService>((ref) {
  return _gmailApiServiceInstance;
});

/// Provider for GmailAuthService
final gmailAuthServiceProvider = Provider<GmailAuthService>((ref) {
  final authService = GmailAuthService();
  // Link to GmailApiService so it can cache token after connect
  authService.setGmailApiService(_gmailApiServiceInstance);
  return authService;
});

/// Keys for SharedPreferences storage
class _EmailSyncKeys {
  static const gmailEmail = 'email_sync_gmail_email';
  static const isEnabled = 'email_sync_is_enabled';
  static const lastSyncTime = 'email_sync_last_sync_time';
  static const enabledBanks = 'email_sync_enabled_banks';
  static const totalImported = 'email_sync_total_imported';
  static const pendingReview = 'email_sync_pending_review';
}

/// Default list of bank domains to scan
const List<String> defaultBankDomains = [
  // Vietnam - Major banks
  'vietcombank.com.vn',
  'bidv.com.vn',
  'techcombank.com.vn',
  'vpbank.com.vn',
  'mbbank.com.vn',
  'acb.com.vn',
  'tpb.vn',
  'sacombank.com.vn',
  'hdbank.com.vn',
  'vib.com.vn',
  // International
  'chase.com',
  'citi.com',
  'notifications.citi.com',
  'hsbc.com',
  'bankofamerica.com',
  'alerts.bankofamerica.com',
  'wellsfargo.com',
  'capitalone.com',
  'email.capitalone.com',
  // E-wallets
  'momo.vn',
  'zalopay.vn',
];

/// Notifier for email sync settings state
class EmailSyncNotifier extends AsyncNotifier<EmailSyncSettingsModel?> {
  @override
  Future<EmailSyncSettingsModel?> build() async {
    return await _loadSettings();
  }

  /// Load settings from SharedPreferences
  Future<EmailSyncSettingsModel?> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_EmailSyncKeys.gmailEmail);

    if (email == null) {
      return null; // Not connected
    }

    final isEnabled = prefs.getBool(_EmailSyncKeys.isEnabled) ?? false;
    final lastSyncMs = prefs.getInt(_EmailSyncKeys.lastSyncTime);
    final enabledBanksJson = prefs.getStringList(_EmailSyncKeys.enabledBanks);
    final totalImported = prefs.getInt(_EmailSyncKeys.totalImported) ?? 0;
    final pendingReview = prefs.getInt(_EmailSyncKeys.pendingReview) ?? 0;

    return EmailSyncSettingsModel(
      gmailEmail: email,
      isEnabled: isEnabled,
      lastSyncTime: lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs)
          : null,
      enabledBanks: enabledBanksJson ?? defaultBankDomains,
      totalImported: totalImported,
      pendingReview: pendingReview,
    );
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings(EmailSyncSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();

    if (settings.gmailEmail != null) {
      await prefs.setString(_EmailSyncKeys.gmailEmail, settings.gmailEmail!);
    } else {
      await prefs.remove(_EmailSyncKeys.gmailEmail);
    }

    await prefs.setBool(_EmailSyncKeys.isEnabled, settings.isEnabled);

    if (settings.lastSyncTime != null) {
      await prefs.setInt(
        _EmailSyncKeys.lastSyncTime,
        settings.lastSyncTime!.millisecondsSinceEpoch,
      );
    }

    await prefs.setStringList(_EmailSyncKeys.enabledBanks, settings.enabledBanks);
    await prefs.setInt(_EmailSyncKeys.totalImported, settings.totalImported);
    await prefs.setInt(_EmailSyncKeys.pendingReview, settings.pendingReview);
  }

  /// Connect Gmail account for email sync
  Future<GmailConnectResult> connectGmail() async {
    final authService = ref.read(gmailAuthServiceProvider);
    final result = await authService.connectGmail();

    if (result is GmailConnectSuccess) {
      final settings = EmailSyncSettingsModel(
        gmailEmail: result.email,
        isEnabled: true,
        enabledBanks: defaultBankDomains,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _saveSettings(settings);
      state = AsyncData(settings);
    }

    return result;
  }

  /// Disconnect Gmail account
  Future<void> disconnectGmail() async {
    final authService = ref.read(gmailAuthServiceProvider);
    await authService.disconnectGmail();

    // Clear settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_EmailSyncKeys.gmailEmail);
    await prefs.remove(_EmailSyncKeys.isEnabled);
    await prefs.remove(_EmailSyncKeys.lastSyncTime);
    await prefs.remove(_EmailSyncKeys.enabledBanks);
    await prefs.remove(_EmailSyncKeys.totalImported);
    await prefs.remove(_EmailSyncKeys.pendingReview);

    state = const AsyncData(null);
  }

  /// Helper to get current value from AsyncValue
  EmailSyncSettingsModel? _getCurrentValue() {
    return state.when(
      data: (data) => data,
      loading: () => null,
      error: (_, __) => null,
    );
  }

  /// Toggle email sync enabled/disabled
  Future<void> setEnabled(bool enabled) async {
    final current = _getCurrentValue();
    if (current == null) return;

    final updated = current.copyWith(
      isEnabled: enabled,
      updatedAt: DateTime.now(),
    );

    await _saveSettings(updated);
    state = AsyncData(updated);
  }

  /// Toggle a specific bank domain
  Future<void> toggleBank(String domain, bool enabled) async {
    final current = _getCurrentValue();
    if (current == null) return;

    final banks = List<String>.from(current.enabledBanks);
    if (enabled && !banks.contains(domain)) {
      banks.add(domain);
    } else if (!enabled) {
      banks.remove(domain);
    }

    final updated = current.copyWith(
      enabledBanks: banks,
      updatedAt: DateTime.now(),
    );

    await _saveSettings(updated);
    state = AsyncData(updated);
  }

  /// Update sync statistics (called after sync completes)
  Future<void> updateSyncStats({
    DateTime? lastSyncTime,
    int? totalImported,
    int? pendingReview,
  }) async {
    final current = _getCurrentValue();
    if (current == null) return;

    final updated = current.copyWith(
      lastSyncTime: lastSyncTime ?? current.lastSyncTime,
      totalImported: totalImported ?? current.totalImported,
      pendingReview: pendingReview ?? current.pendingReview,
      updatedAt: DateTime.now(),
    );

    await _saveSettings(updated);
    state = AsyncData(updated);
  }

  /// Refresh settings from storage
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadSettings());
  }
}

/// Provider for email sync settings
final emailSyncProvider = AsyncNotifierProvider<EmailSyncNotifier, EmailSyncSettingsModel?>(
  EmailSyncNotifier.new,
);

/// Helper to unwrap AsyncValue
EmailSyncSettingsModel? _unwrapEmailSyncValue(AsyncValue<EmailSyncSettingsModel?> asyncValue) {
  return asyncValue.when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );
}

/// Provider for checking if email sync is connected
final isEmailSyncConnectedProvider = Provider<bool>((ref) {
  final settings = _unwrapEmailSyncValue(ref.watch(emailSyncProvider));
  return settings?.gmailEmail != null;
});

/// Provider for checking if email sync is enabled
final isEmailSyncEnabledProvider = Provider<bool>((ref) {
  final settings = _unwrapEmailSyncValue(ref.watch(emailSyncProvider));
  return settings?.isEnabled ?? false;
});

/// Provider for email sync status
final emailSyncStatusProvider = Provider<EmailSyncStatus>((ref) {
  final settings = _unwrapEmailSyncValue(ref.watch(emailSyncProvider));

  if (settings == null || settings.gmailEmail == null) {
    return EmailSyncStatus.disconnected;
  }

  if (!settings.isEnabled) {
    return EmailSyncStatus.paused;
  }

  return EmailSyncStatus.connected;
});
