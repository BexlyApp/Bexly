import 'package:go_router/go_router.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/family/presentation/screens/family_settings_screen.dart';
import 'package:bexly/features/family/presentation/screens/invite_member_screen.dart';
import 'package:bexly/features/family/presentation/screens/share_wallet_screen.dart';

class FamilyRouter {
  static final routes = <GoRoute>[
    GoRoute(
      path: Routes.familySettings,
      builder: (context, state) => const FamilySettingsScreen(),
    ),
    GoRoute(
      path: Routes.inviteMember,
      builder: (context, state) => const InviteMemberScreen(),
    ),
    GoRoute(
      path: Routes.shareWallet,
      builder: (context, state) => const ShareWalletScreen(),
    ),
  ];
}
