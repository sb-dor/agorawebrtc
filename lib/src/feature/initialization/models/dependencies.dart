import 'package:flutter/widgets.dart';
import 'package:flutter_project/src/common/database/database.dart';
import 'package:flutter_project/src/common/model/app_metadata.dart';
import 'package:flutter_project/src/common/util/api_client.dart';
import 'package:flutter_project/src/feature/authentication/controller/authentication_controller.dart';
import 'package:flutter_project/src/feature/initialization/widget/dependencies_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// {@template dependencies}
/// Application dependencies.
/// {@endtemplate}
class Dependencies {
  /// {@macro dependencies}
  Dependencies();

  /// The state from the closest instance of this class.
  ///
  /// {@macro dependencies}
  factory Dependencies.of(BuildContext context) => DependenciesScope.of(context);

  /// Injest dependencies to the widget tree.
  Widget inject({required Widget child, Key? key}) =>
      DependenciesScope(dependencies: this, key: key, child: child);

  /// App metadata
  late final AppMetadata metadata;

  /// Shared preferences
  late final SharedPreferences sharedPreferences;

  /// Database
  late final AppDatabase database;

  /// API Client
  late final ApiClient apiClient;

  /// Authentication controller
  late final AuthenticationController authenticationController;

  @override
  String toString() => 'Dependencies{}';
}

/// Fake Dependencies
@visibleForTesting
class FakeDependencies extends Dependencies {
  FakeDependencies();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // ... implement fake dependencies
    throw UnimplementedError();
  }
}
