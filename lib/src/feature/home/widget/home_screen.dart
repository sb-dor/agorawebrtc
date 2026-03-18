import 'package:flutter/widgets.dart';
import 'package:flutter_project/src/feature/call/widgets/call_config_widget.dart';

/// {@template home_screen}
/// HomeScreen widget — entry point for the call feature.
/// {@endtemplate}
class HomeScreen extends StatelessWidget {
  /// {@macro home_screen}
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const CallConfigWidget();
}
