import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bexly/core/services/package_info/package_info_provider.dart';
import 'package:bexly/core/utils/logger.dart';

/// Result of comparing the installed build against the server-side minimum.
class VersionCheckResult {
  final bool updateRequired;
  final int currentBuild;
  final int minBuild;
  final String? message;
  final String? storeUrl;

  const VersionCheckResult({
    required this.updateRequired,
    required this.currentBuild,
    required this.minBuild,
    this.message,
    this.storeUrl,
  });

  static const VersionCheckResult passthrough = VersionCheckResult(
    updateRequired: false,
    currentBuild: 0,
    minBuild: 0,
  );
}

/// Reads `bexly.app_min_versions` for the current platform and decides
/// whether the running build must update before continuing.
///
/// Network failures are treated as "no update required" — better to let
/// the user in than to block them on a transient outage.
class VersionCheckService {
  VersionCheckService(this._packageInfo);

  final PackageInfoService _packageInfo;
  static const _label = 'VersionCheck';

  Future<VersionCheckResult> check() async {
    if (!_packageInfo.isInitialized) {
      Log.w('PackageInfo not ready — skipping version check', label: _label);
      return VersionCheckResult.passthrough;
    }

    final currentBuild = int.tryParse(_packageInfo.buildNumber) ?? 0;
    if (currentBuild == 0) {
      // Local/dev build with non-numeric buildNumber: skip.
      return VersionCheckResult.passthrough;
    }

    final platform = _platformKey();
    if (platform == null) return VersionCheckResult.passthrough;

    try {
      final row = await Supabase.instance.client
          .schema('bexly')
          .from('app_min_versions')
          .select('min_build_number, message, store_url')
          .eq('platform', platform)
          .maybeSingle();

      if (row == null) return VersionCheckResult.passthrough;

      final minBuild = (row['min_build_number'] as num?)?.toInt() ?? 0;
      if (currentBuild >= minBuild) {
        return VersionCheckResult(
          updateRequired: false,
          currentBuild: currentBuild,
          minBuild: minBuild,
        );
      }

      Log.w(
        'Force update required: current=$currentBuild < min=$minBuild ($platform)',
        label: _label,
      );
      return VersionCheckResult(
        updateRequired: true,
        currentBuild: currentBuild,
        minBuild: minBuild,
        message: row['message'] as String?,
        storeUrl: row['store_url'] as String?,
      );
    } catch (e) {
      Log.e('Version check failed (ignored): $e', label: _label);
      return VersionCheckResult.passthrough;
    }
  }

  String? _platformKey() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isWindows) return 'windows';
    return null;
  }
}

final versionCheckServiceProvider = Provider<VersionCheckService>((ref) {
  return VersionCheckService(ref.read(packageInfoServiceProvider));
});

/// Async provider that runs the check once on app start.
/// Consumers can `ref.watch` it and gate the UI on the result.
final versionCheckResultProvider = FutureProvider<VersionCheckResult>((ref) {
  return ref.read(versionCheckServiceProvider).check();
});
