/// Type of workspace being viewed
enum WorkspaceType {
  /// Personal workspace - user's own wallets and transactions
  personal,

  /// Family workspace - shared wallets and transactions
  family,
}

extension WorkspaceTypeExtension on WorkspaceType {
  String get displayName {
    switch (this) {
      case WorkspaceType.personal:
        return 'Personal';
      case WorkspaceType.family:
        return 'Family';
    }
  }

  String get description {
    switch (this) {
      case WorkspaceType.personal:
        return 'Your personal wallets and transactions';
      case WorkspaceType.family:
        return 'Wallets and transactions shared with your family';
    }
  }
}
