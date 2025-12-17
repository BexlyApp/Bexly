/// Role of a member in a family group
enum FamilyRole {
  /// Owner has full control: manage members, share wallets, CRUD transactions
  owner,

  /// Editor can share wallets and CRUD transactions
  editor,

  /// Viewer can only view shared data (read-only)
  viewer,
}

extension FamilyRoleExtension on FamilyRole {
  String get displayName {
    switch (this) {
      case FamilyRole.owner:
        return 'Owner';
      case FamilyRole.editor:
        return 'Editor';
      case FamilyRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case FamilyRole.owner:
        return 'Full control over family settings, members, and shared data';
      case FamilyRole.editor:
        return 'Can add/edit transactions and share wallets';
      case FamilyRole.viewer:
        return 'Can view shared wallets and transactions (read-only)';
    }
  }

  String toDbString() => name;

  static FamilyRole fromDbString(String value) {
    return FamilyRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FamilyRole.viewer,
    );
  }

  /// Check if this role can invite new members
  bool get canInviteMembers => this == FamilyRole.owner;

  /// Check if this role can remove members
  bool get canRemoveMembers => this == FamilyRole.owner;

  /// Check if this role can share/unshare wallets
  bool get canShareWallets =>
      this == FamilyRole.owner || this == FamilyRole.editor;

  /// Check if this role can create/edit/delete transactions
  bool get canEditTransactions =>
      this == FamilyRole.owner || this == FamilyRole.editor;

  /// Check if this role can view shared data
  bool get canViewSharedData => true;

  /// Check if this role can edit family settings (name, icon, etc.)
  bool get canEditFamilySettings => this == FamilyRole.owner;

  /// Check if this role can delete the family group
  bool get canDeleteFamily => this == FamilyRole.owner;
}
