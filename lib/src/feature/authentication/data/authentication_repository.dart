import 'package:flutter_project/src/common/util/api_client.dart';
import 'package:flutter_project/src/feature/authentication/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class IAuthenticationRepository {}

class AuthenticationRepositoryImpl implements IAuthenticationRepository {
  AuthenticationRepositoryImpl({
    required final SharedPreferences sharedPreferences,
    required final ApiClient apiClient,
  }) : _sharedPreferences = sharedPreferences,
       _apiClient = apiClient;

  // ignore: unused_field
  final SharedPreferences _sharedPreferences;
  // ignore: unused_field
  final ApiClient _apiClient;
}

class AuthenticationRepositoryFake implements IAuthenticationRepository {
  User get defaultUser => User.defaultUser();
}
