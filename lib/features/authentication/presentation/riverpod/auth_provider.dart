import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/daos/user_dao.dart';
import 'package:bexly/core/database/database_provider.dart';
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
      await _userDao.updateUser(
        state.copyWith(id: existingUser.id).toCompanion(),
      );
      Log.i(state.toJson(), label: 'updated user session');
    } else {
      // Insert a new user
      final newId = await _userDao.insertUser(state.toCompanion());
      state = state.copyWith(id: newId); // Update state with the new ID from DB
      Log.i(state.toJson(), label: 'created user session');
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
    await _userDao.deleteAllUsers();
    state = UserRepository.dummy;
  }
}

final authStateProvider = NotifierProvider<AuthProvider, UserModel>(AuthProvider.new);
