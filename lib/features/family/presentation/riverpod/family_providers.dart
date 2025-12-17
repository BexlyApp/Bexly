import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/daos/family_dao.dart';
import 'package:bexly/features/family/data/models/family_group_model.dart';
import 'package:bexly/features/family/data/models/family_member_model.dart';
import 'package:bexly/features/family/data/models/family_invitation_model.dart';
import 'package:bexly/features/family/data/models/shared_wallet_model.dart';

/// Provider for FamilyDao
final familyDaoProvider = Provider<FamilyDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.familyDao;
});

/// Stream provider for all family groups
final familyGroupsProvider = StreamProvider<List<FamilyGroupModel>>((ref) {
  final dao = ref.watch(familyDaoProvider);
  return dao.watchFamilyGroups();
});

/// Notifier for current active family (selected family group)
class CurrentFamilyNotifier extends Notifier<FamilyGroupModel?> {
  @override
  FamilyGroupModel? build() => null;

  void setFamily(FamilyGroupModel? family) {
    state = family;
  }

  void clear() {
    state = null;
  }
}

/// Provider for current active family
final currentFamilyProvider = NotifierProvider<CurrentFamilyNotifier, FamilyGroupModel?>(
  CurrentFamilyNotifier.new,
);

/// Stream provider for members of current family
final familyMembersProvider = StreamProvider<List<FamilyMemberModel>>((ref) {
  final currentFamily = ref.watch(currentFamilyProvider);
  if (currentFamily == null || currentFamily.id == null) {
    return Stream.value([]);
  }
  final dao = ref.watch(familyDaoProvider);
  return dao.watchActiveFamilyMembers(currentFamily.id!);
});

/// Stream provider for pending invitations for current family
final pendingInvitationsProvider = StreamProvider<List<FamilyInvitationModel>>((ref) {
  final currentFamily = ref.watch(currentFamilyProvider);
  if (currentFamily == null || currentFamily.id == null) {
    return Stream.value([]);
  }
  final dao = ref.watch(familyDaoProvider);
  return dao.watchPendingInvitations(currentFamily.id!);
});

/// Stream provider for shared wallets in current family
final sharedWalletsProvider = StreamProvider<List<SharedWalletModel>>((ref) {
  final currentFamily = ref.watch(currentFamilyProvider);
  if (currentFamily == null || currentFamily.id == null) {
    return Stream.value([]);
  }
  final dao = ref.watch(familyDaoProvider);
  return dao.watchSharedWallets(currentFamily.id!);
});

/// Stream provider for invitations received by email
final receivedInvitationsProvider = StreamProvider.family<List<FamilyInvitationModel>, String>((ref, email) {
  final dao = ref.watch(familyDaoProvider);
  return dao.watchInvitationsForEmail(email);
});

/// Provider to check if user has an active family
final hasActiveFamilyProvider = Provider<bool>((ref) {
  final currentFamily = ref.watch(currentFamilyProvider);
  return currentFamily != null;
});

/// Provider for family member count
final familyMemberCountProvider = Provider<int>((ref) {
  final members = ref.watch(familyMembersProvider);
  return members.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
