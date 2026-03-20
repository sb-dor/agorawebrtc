import 'package:flutter/material.dart';

/// Shown in the video area when no remote participants have joined yet.
class WaitingView extends StatelessWidget {
  const WaitingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_search, size: 72, color: Colors.white24),
        SizedBox(height: 16),
        Text('Waiting for others to join…', style: TextStyle(color: Colors.white54, fontSize: 16)),
      ],
    ),
  );
}
