import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/daos/wallet_dao.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/wallet/data/repositories/wallet_repo.dart'; // Assuming defaultWallets is here

class WalletPopulationService {
  /// Populate using AppDatabase (no sync - with offline support)
  static Future<void> populate(AppDatabase db) async {
    Log.i('Populating default wallets...', label: 'wallet');
    for (final walletModel in defaultWallets) {
      try {
        await db.walletDao.addWallet(walletModel);
        Log.d(
          'Successfully added default wallet: ${walletModel.name}',
          label: 'wallet',
        );
      } catch (e) {
        Log.e(
          'Failed to add default wallet ${walletModel.name}: $e',
          label: 'wallet',
        );
      }
    }

    Log.i(
      'Default wallets populated successfully: (${defaultWallets.length})',
      label: 'wallet',
    );
  }

  /// Populate using WalletDao with Ref (triggers sync)
  static Future<void> populateWithDao(WalletDao walletDao) async {
    Log.i('Populating default wallets with sync...', label: 'wallet');
    for (final walletModel in defaultWallets) {
      try {
        await walletDao.addWallet(walletModel);
        Log.d(
          'Successfully added default wallet with sync: ${walletModel.name}',
          label: 'wallet',
        );
      } catch (e) {
        Log.e(
          'Failed to add default wallet ${walletModel.name}: $e',
          label: 'wallet',
        );
      }
    }

    Log.i(
      'Default wallets populated successfully with sync: (${defaultWallets.length})',
      label: 'wallet',
    );
  }
}
