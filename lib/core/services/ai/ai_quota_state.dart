import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Snapshot of the user's AI quota for the current billing period, captured
/// from `X-RateLimit-*` headers on the most recent gateway response.
class AiQuotaState {
  final int? limit;
  final int? remaining;
  final DateTime? resetAt;
  final String? tier; // 'standard' | 'premium' | 'flagship'
  final DateTime? lastUpdated;

  const AiQuotaState({
    this.limit,
    this.remaining,
    this.resetAt,
    this.tier,
    this.lastUpdated,
  });

  static const AiQuotaState unknown = AiQuotaState();

  bool get hasData => limit != null;
  bool get isExhausted => remaining != null && remaining! <= 0;
  double? get usedFraction =>
      (limit == null || limit == 0) ? null : 1.0 - (remaining ?? 0) / limit!;
}

class AiQuotaNotifier extends Notifier<AiQuotaState> {
  @override
  AiQuotaState build() => AiQuotaState.unknown;

  /// Update from response headers. Headers map should be lower-case keyed
  /// (Dart's `http` package lower-cases automatically).
  void updateFromHeaders(Map<String, String> headers) {
    final limit = int.tryParse(headers['x-ratelimit-limit'] ?? '');
    final remaining = int.tryParse(headers['x-ratelimit-remaining'] ?? '');
    final resetUnix = int.tryParse(headers['x-ratelimit-reset'] ?? '');
    final tier = headers['x-ratelimit-tier'];

    if (limit == null && remaining == null && resetUnix == null) {
      // No quota headers in this response — leave state untouched.
      return;
    }

    state = AiQuotaState(
      limit: limit ?? state.limit,
      remaining: remaining ?? state.remaining,
      resetAt: resetUnix != null
          ? DateTime.fromMillisecondsSinceEpoch(resetUnix * 1000, isUtc: true)
          : state.resetAt,
      tier: tier ?? state.tier,
      lastUpdated: DateTime.now(),
    );
  }

  /// Mark exhausted on 429 even if headers are absent.
  void markExhausted() {
    state = AiQuotaState(
      limit: state.limit,
      remaining: 0,
      resetAt: state.resetAt,
      tier: state.tier,
      lastUpdated: DateTime.now(),
    );
  }
}

final aiQuotaProvider = NotifierProvider<AiQuotaNotifier, AiQuotaState>(
  AiQuotaNotifier.new,
);
