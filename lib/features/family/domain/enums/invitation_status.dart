/// Status of a family invitation
enum InvitationStatus {
  /// Invitation is pending response
  pending,

  /// Invitation was accepted
  accepted,

  /// Invitation was rejected by invitee
  rejected,

  /// Invitation has expired
  expired,

  /// Invitation was cancelled by inviter
  cancelled,
}

extension InvitationStatusExtension on InvitationStatus {
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.rejected:
        return 'Rejected';
      case InvitationStatus.expired:
        return 'Expired';
      case InvitationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String toDbString() => name;

  static InvitationStatus fromDbString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvitationStatus.pending,
    );
  }

  /// Check if the invitation can still be responded to
  bool get canRespond => this == InvitationStatus.pending;

  /// Check if the invitation is in a final state
  bool get isFinal =>
      this == InvitationStatus.accepted ||
      this == InvitationStatus.rejected ||
      this == InvitationStatus.expired ||
      this == InvitationStatus.cancelled;
}
