import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bexly/features/ai_chat/data/services/bexly_agent_service.dart';

/// Provides a singleton [BexlyAgentService] instance for the AI chat feature.
///
/// Consumed by chat UI once [LLMDefaultConfig.useBexlyAgent] is true.
/// Until Phase 3.1.5 enables the feature flag in dev, the legacy ai-proxy
/// path in [ChatNotifier] remains the active default.
final bexlyAgentServiceProvider = Provider<BexlyAgentService>(
  (ref) => BexlyAgentService(),
);
