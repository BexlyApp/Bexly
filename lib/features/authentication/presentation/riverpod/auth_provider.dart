import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/database/daos/user_dao.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/authentication/data/repositories/user_repository.dart';
import 'package:bexly/features/authentication/data/models/user_model.dart';

// Provider for the UserDao
final userDaoProvider = Provider<UserDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.userDao;
});

final authProvider = FutureProvider<UserModel?>((ref) async {
  return await ref.read(authStateProvider.notifier).getSession();
});

class AuthProvider extends Notifier<UserModel> {
  late final UserDao _userDao;

  @override
  UserModel build() {
    _userDao = ref.watch(userDaoProvider);
    // Automatically load session from database on initialization
    _initializeSession();
    return UserRepository.dummy;
  }

  Future<void> _initializeSession() async {
    final userFromDb = await _userDao.getFirstUser();
    if (userFromDb != null) {
      state = userFromDb.toModel();
      Log.i(state.toJson(), label: 'auto-loaded user session on provider init');
    }
  }

  void setUser(UserModel user) {
    Log.i('🔵 setUser() called with: ${user.toJson()}', label: 'AuthProvider');
    state = user;
    _setSession();
  }

  Future<void> setImage(String? imagePath) async {
    state = state.copyWith(profilePicture: imagePath);
    await _setSession();
  }

  UserModel getUser() => state;

  Future<void> _setSession() async {
    final existingUser = await _userDao.getFirstUser();

    if (existingUser != null) {
      // Update the user, ensuring the ID from the database is preserved
      final updatedUser = state.copyWith(id: existingUser.id);
      Log.i('🟢 Updating user in DB: ${updatedUser.toJson()}', label: 'AuthProvider');
      await _userDao.updateUser(updatedUser.toCompanion());
      Log.i('✅ User session updated in DB', label: 'AuthProvider');
    } else {
      // Insert a new user
      Log.i('🟡 Creating new user in DB: ${state.toJson()}', label: 'AuthProvider');
      final newId = await _userDao.insertUser(state.toCompanion());
      state = state.copyWith(id: newId); // Update state with the new ID from DB
      Log.i('✅ User session created in DB with ID: $newId', label: 'AuthProvider');
    }
  }

  Future<UserModel?> getSession() async {
    final userFromDb = await _userDao.getFirstUser();
    if (userFromDb != null) {
      final userModel = userFromDb.toModel();
      state = userModel;
      Log.i(userModel.toJson(), label: 'user session from db');
      return userModel;
    }

    Log.i(null, label: 'no user session in db');
    return null;
  }

  Future<void> logout() async {
    // Clear ALL local data for security (finance app - sensitive data)
    try {
      final db = ref.read(databaseProvider);
      await db.clearAllTables();
      Log.i('✅ All local tables cleared', label: 'AuthProvider');
    } catch (e) {
      Log.e('⚠️ Failed to clear local tables: $e', label: 'AuthProvider');
    }
    state = UserRepository.dummy;

    // Clear guest mode flag
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSkippedAuth', false);
    } catch (e) {
      Log.e('⚠️ Failed to clear SharedPreferences: $e', label: 'AuthProvider');
    }

    // Clear Supabase session (fire-and-forget, don't block UI)
    SupabaseInitService.client.auth.signOut().then((_) {
      Log.i('✅ Supabase session cleared', label: 'AuthProvider');
    }).catchError((e) {
      Log.e('⚠️ Failed to clear Supabase session: $e', label: 'AuthProvider');
    });

    Log.i('✅ Logout complete', label: 'AuthProvider');
  }
}

final authStateProvider = NotifierProvider<AuthProvider, UserModel>(AuthProvider.new);
