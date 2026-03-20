import 'package:flutter/widgets.dart';
import 'package:flutter_project/src/feature/meeting/widgets/meeting_screen.dart';

/// {@template home_screen}
/// HomeScreen widget — entry point for the meeting lobby.
/// {@endtemplate}
class HomeScreen extends StatelessWidget {
  /// {@macro home_screen}
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const MeetingScreen();
}
