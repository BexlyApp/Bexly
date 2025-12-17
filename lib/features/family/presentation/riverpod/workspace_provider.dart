import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/features/family/domain/enums/workspace_type.dart';

/// Notifier for the current workspace type (Personal or Family)
class WorkspaceNotifier extends Notifier<WorkspaceType> {
  @override
  WorkspaceType build() => WorkspaceType.personal;

  void setWorkspace(WorkspaceType workspace) {
    state = workspace;
  }

  void toggleWorkspace() {
    state = state == WorkspaceType.personal
        ? WorkspaceType.family
        : WorkspaceType.personal;
  }
}

/// Provider for the current workspace type
final currentWorkspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceType>(
  WorkspaceNotifier.new,
);
