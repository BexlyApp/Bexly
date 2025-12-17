/// Status of a family member
enum FamilyMemberStatus {
  /// Invitation sent but not yet accepted
  pending,

  /// Member has accepted invitation and is active
  active,

  /// Member has left the family
  left,
}

extension FamilyMemberStatusExtension on FamilyMemberStatus {
  String get displayName {
    switch (this) {
      case FamilyMemberStatus.pending:
        return 'Pending';
      case FamilyMemberStatus.active:
        return 'Active';
      case FamilyMemberStatus.left:
        return 'Left';
    }
  }

  String toDbString() => name;

  static FamilyMemberStatus fromDbString(String value) {
    return FamilyMemberStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FamilyMemberStatus.pending,
    );
  }
}
