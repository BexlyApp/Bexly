import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_auth_service.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_api_service.dart';
import 'package:bexly/features/email_sync/domain/services/email_sync_worker.dart';
import 'package:bexly/features/email_sync/data/models/email_sync_settings_model.dart';
import 'package:bexly/core/config/supabase_config.dart';
import 'package:bexly/core/services/dosme_oauth/dosme_oauth.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Provider for GmailApiService (shared singleton)
final _gmailApiServiceInstance = GmailApiService();

/// Provider for GmailApiService
/// When USE_DOSME_OAUTH=true, this will use dos.me ID for token management
final gmailApiServiceProvider = Provider<GmailApiService>((ref) {
  final service = _gmailApiServiceInstance;

  // Configure dos.me ID token provider when enabled
  if (SupabaseConfig.useDosmeOAuth) {
    final dosmeService = ref.watch(dosmeOAuthServiceProvider);
    service.setExternalTokenProvider(() async {
      final result = await dosmeService.getGmailAccessToken();
      switch (result) {
        case DosmeOAuthSuccess(data: final token):
          return token.accessToken;
        case DosmeOAuthFailure(error: final err):
          Log.w('dos.me OAuth error: ${err.code} - ${err.message}', label: 'EmailSync');
          return null;
      }
    });
    Log.i('GmailApiService configured with dos.me ID token provider', label: 'EmailSync');
  }

  return service;
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
  static const syncFrequency = 'email_sync_sync_frequency';
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
    final local = await _loadSettings();
    if (local != null) return local;

    // No local settings — try to restore from dos.me ID server
    return await _tryRestoreFromDosme();
  }

  /// Check dos.me ID server for existing Gmail connection and restore locally
  Future<EmailSyncSettingsModel?> _tryRestoreFromDosme() async {
    if (!SupabaseConfig.useDosmeOAuth) return null;

    // Only restore if user is authenticated
    final session = SupabaseInitService.currentSession;
    if (session == null) return null;

    try {
      Log.i('Checking dos.me ID for existing Gmail connection...', label: 'EmailSync');
      final dosmeService = ref.read(dosmeOAuthServiceProvider);
      final email = await dosmeService.getConnectedGmailEmail();

      if (email != null) {
        Log.i('Restored Gmail connection from dos.me ID: $email', label: 'EmailSync');
        await _saveGmailConnection(email);
        return await _loadSettings();
      }
    } catch (e) {
      Log.w('Failed to restore email sync from dos.me ID: $e', label: 'EmailSync');
    }

    return null;
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
    final syncFreqString = prefs.getString(_EmailSyncKeys.syncFrequency);
    final syncFrequency = syncFreqString != null
        ? SyncFrequency.fromString(syncFreqString)
        : SyncFrequency.every24Hours;

    return EmailSyncSettingsModel(
      gmailEmail: email,
      isEnabled: isEnabled,
      lastSyncTime: lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs)
          : null,
      enabledBanks: enabledBanksJson ?? defaultBankDomains,
      totalImported: totalImported,
      pendingReview: pendingReview,
      syncFrequency: syncFrequency,
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
    await prefs.setString(_EmailSyncKeys.syncFrequency, settings.syncFrequency.name);
  }

  /// Connect Gmail account for email sync
  ///
  /// When USE_DOSME_OAUTH=true:
  /// - Opens dos.me ID connect URL in browser
  /// - Returns GmailConnectPendingBrowser
  /// - User completes OAuth in browser, then call refreshDosmeConnection()
  ///
  /// When USE_DOSME_OAUTH=false:
  /// - Uses local Google Sign In
  Future<GmailConnectResult> connectGmail() async {
    // dos.me ID mode: open browser for OAuth
    if (SupabaseConfig.useDosmeOAuth) {
      return _connectGmailViaDosme();
    }

    // Local mode: use Google Sign In
    final authService = ref.read(gmailAuthServiceProvider);
    final result = await authService.connectGmail();

    if (result is GmailConnectSuccess) {
      await _saveGmailConnection(result.email);
    }

    return result;
  }

  /// Connect Gmail via dos.me ID using native auth + exchange
  ///
  /// Flow:
  /// 1. Native Google Sign In → get auth code
  /// 2. Send auth code to dos.me ID for exchange
  /// 3. dos.me ID stores refresh token securely
  Future<GmailConnectResult> _connectGmailViaDosme() async {
    try {
      final dosmeService = ref.read(dosmeOAuthServiceProvider);
      final authService = ref.read(gmailAuthServiceProvider);

      // Check if already connected via dos.me ID
      final existingEmail = await dosmeService.getConnectedGmailEmail();
      if (existingEmail != null) {
        Log.i('Gmail already connected via dos.me ID: $existingEmail', label: 'EmailSync');
        await _saveGmailConnection(existingEmail);
        return GmailConnectSuccess(email: existingEmail);
      }

      // Step 1: Native Google Sign In to get auth code
      Log.i('Starting native Google Sign In for dos.me ID...', label: 'EmailSync');
      final authResult = await authService.connectGmailWithAuthCode();

      // Handle auth result
      switch (authResult) {
        case GmailConnectWithAuthCode(email: final email, authCode: final code):
          // Step 2: Exchange auth code with dos.me ID
          Log.i('Got auth code, exchanging with dos.me ID...', label: 'EmailSync');
          final exchangeResult = await dosmeService.exchangeGmailAuthCode(code: code);

          switch (exchangeResult) {
            case DosmeOAuthSuccess(data: final response):
              Log.i('Gmail connected via dos.me ID: ${response.email}', label: 'EmailSync');
              await _saveGmailConnection(response.email);
              return GmailConnectSuccess(email: response.email);

            case DosmeOAuthFailure(error: final error):
              Log.e('dos.me ID exchange failed: ${error.code} - ${error.message}', label: 'EmailSync');
              // Fallback: use local token (already cached during auth)
              Log.w('Falling back to local token mode for $email', label: 'EmailSync');
              await _saveGmailConnection(email);
              return GmailConnectSuccess(email: email);
          }

        case GmailConnectSuccess(email: final email):
          // Fallback: No auth code available, but got access token
          // This happens when serverClientId is not configured
          Log.w('No auth code available, using local token only', label: 'EmailSync');
          await _saveGmailConnection(email);
          return GmailConnectSuccess(email: email);

        case GmailConnectCancelled():
          return const GmailConnectCancelled();

        case GmailConnectError(message: final msg, error: final err):
          return GmailConnectError(msg, err);

        case GmailConnectPendingBrowser():
          // This shouldn't happen in native flow
          return const GmailConnectError('Unexpected browser flow in native mode');
      }
    } catch (e) {
      Log.e('Error connecting Gmail via dos.me ID: $e', label: 'EmailSync');
      return GmailConnectError('Failed to connect Gmail: $e', e);
    }
  }

  /// Refresh dos.me ID connection status (call after user returns from browser)
  Future<GmailConnectResult> refreshDosmeConnection() async {
    if (!SupabaseConfig.useDosmeOAuth) {
      return const GmailConnectError('dos.me OAuth mode is not enabled');
    }

    try {
      final dosmeService = ref.read(dosmeOAuthServiceProvider);
      final email = await dosmeService.getConnectedGmailEmail();

      if (email != null) {
        Log.i('Gmail connected via dos.me ID: $email', label: 'EmailSync');
        await _saveGmailConnection(email);
        return GmailConnectSuccess(email: email);
      } else {
        Log.w('Gmail not connected via dos.me ID', label: 'EmailSync');
        return const GmailConnectError('Gmail not connected. Please complete the connection in browser.');
      }
    } catch (e) {
      Log.e('Error checking dos.me ID connection: $e', label: 'EmailSync');
      return GmailConnectError('Failed to check connection: $e', e);
    }
  }

  /// Save Gmail connection settings
  Future<void> _saveGmailConnection(String email) async {
    final settings = EmailSyncSettingsModel(
      gmailEmail: email,
      isEnabled: true,
      enabledBanks: defaultBankDomains,
      syncFrequency: SyncFrequency.every24Hours,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _saveSettings(settings);
    state = AsyncData(settings);

    // Register background sync (default: 24 hours)
    await _registerBackgroundSync(settings.syncFrequency);
  }

  /// Disconnect Gmail account
  Future<void> disconnectGmail() async {
    final authService = ref.read(gmailAuthServiceProvider);
    await authService.disconnectGmail();

    // Cancel background sync
    await EmailSyncWorker.cancelPeriodicSync();

    // Clear settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_EmailSyncKeys.gmailEmail);
    await prefs.remove(_EmailSyncKeys.isEnabled);
    await prefs.remove(_EmailSyncKeys.lastSyncTime);
    await prefs.remove(_EmailSyncKeys.enabledBanks);
    await prefs.remove(_EmailSyncKeys.totalImported);
    await prefs.remove(_EmailSyncKeys.pendingReview);
    await prefs.remove(_EmailSyncKeys.syncFrequency);

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

  /// Set sync frequency and update background task
  Future<void> setSyncFrequency(SyncFrequency frequency) async {
    final current = _getCurrentValue();
    if (current == null) return;

    Log.i('Setting sync frequency to: ${frequency.name}', label: 'EmailSync');

    final updated = current.copyWith(
      syncFrequency: frequency,
      updatedAt: DateTime.now(),
    );

    await _saveSettings(updated);
    state = AsyncData(updated);

    // Update background sync task
    await _registerBackgroundSync(frequency);
  }

  /// Register or cancel background sync based on frequency
  Future<void> _registerBackgroundSync(SyncFrequency frequency) async {
    try {
      if (frequency == SyncFrequency.manual) {
        // Manual only - cancel background task
        Log.i('Cancelling background sync (manual mode)', label: 'EmailSync');
        await EmailSyncWorker.cancelPeriodicSync();
      } else {
        // Register periodic task
        final hours = frequency.hours!;
        Log.i('Registering background sync: every $hours hours', label: 'EmailSync');
        await EmailSyncWorker.registerPeriodicSync(frequencyHours: hours);
      }
    } catch (e) {
      Log.e('Failed to update background sync: $e', label: 'EmailSync');
    }
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
