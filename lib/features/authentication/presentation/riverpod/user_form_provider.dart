import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/authentication/data/repositories/user_repository.dart';
import 'package:bexly/features/authentication/data/models/user_model.dart';

class UserFormNotifier extends Notifier<UserModel> {
  @override
  UserModel build() => UserRepository.dummy;

  void setUser(UserModel user) => state = user;
}

final userProvider = NotifierProvider<UserFormNotifier, UserModel>(
  UserFormNotifier.new,
);
