import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bexly/core/services/version_check_service.dart';

/// Full-screen blocker shown when the installed build is older than
/// `bexly.app_min_versions.min_build_number` for the current platform.
///
/// Covers the entire UI tree — there is intentionally no "skip" affordance
/// because old builds may carry leaked credentials that have been rotated
/// server-side, leaving the app non-functional anyway.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, required this.result});

  final VersionCheckResult result;

  Future<void> _openStore() async {
    final url = result.storeUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.system_update, size: 80, color: Color(0xFF731FE0)),
                  const SizedBox(height: 24),
                  const Text(
                    'Cần cập nhật Bexly',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.message ??
                        'Phiên bản này không còn được hỗ trợ. Vui lòng cập nhật để tiếp tục.',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phiên bản hiện tại: ${result.currentBuild} · Yêu cầu: ${result.minBuild}+',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 32),
                  if (result.storeUrl != null)
                    ElevatedButton(
                      onPressed: _openStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF731FE0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cập nhật ngay', style: TextStyle(fontSize: 16)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
