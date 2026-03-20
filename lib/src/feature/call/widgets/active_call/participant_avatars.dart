import 'package:flutter/material.dart';

/// Circular avatar row used in the audio call view.
class ParticipantAvatars extends StatelessWidget {
  const ParticipantAvatars({super.key, required this.remoteUids});

  final List<int> remoteUids;

  @override
  Widget build(BuildContext context) {
    if (remoteUids.isEmpty) {
      return const CircleAvatar(
        radius: 60,
        backgroundColor: Colors.white12,
        child: Icon(Icons.person, size: 60, color: Colors.white38),
      );
    }
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: remoteUids
          .map(
            (uid) => CircleAvatar(
              radius: 48,
              backgroundColor: Colors.teal.shade700,
              child: Text(
                'U${uid % 100}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
