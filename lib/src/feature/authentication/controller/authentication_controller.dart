import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/src/feature/authentication/data/authentication_repository.dart';
import 'package:flutter_project/src/feature/authentication/model/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'authentication_controller.freezed.dart';

/// for more information to change the controller's handler checkout this github page:
/// https://github.com/PlugFox/control/tree/master/lib/src/concurrency

@freezed
sealed class AuthenticationState with _$AuthenticationState {
  const AuthenticationState._();

  const factory AuthenticationState.idle() = Authentication$IdleState;

  const factory AuthenticationState.inProgress() = Authentication$InProgressState;

  const factory AuthenticationState.error(final String? error) = Authentication$ErrorState;

  const factory AuthenticationState.authenticated(final User user) =
      Authentication$AuthenticatedState;

  String? get error => switch (this) {
    final Authentication$ErrorState state => state.error,
    _ => null,
  };

  User? get user => switch (this) {
    final Authentication$AuthenticatedState state => state.user,
    _ => null,
  };
}

final class AuthenticationController extends StateController<AuthenticationState>
    with DroppableControllerHandler {
  AuthenticationController({
    required this.repository,
    super.initialState = const AuthenticationState.idle(),
  });

  final IAuthenticationRepository repository;

  void signIn(String displayName) => handle(() async {
    final uid = DateTime.now().millisecondsSinceEpoch % 100000 + 1;
    setState(AuthenticationState.authenticated(User(id: uid, name: displayName.trim())));
  });

  void logout() => handle(() async {
    if (state is! Authentication$AuthenticatedState) return;
    setState(const AuthenticationState.idle());
  });
}
