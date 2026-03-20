import 'package:flutter/material.dart';

/// Top overlay bar showing the channel name and participant count.
class CallTopBar extends StatelessWidget {
  const CallTopBar({super.key, required this.channelName, this.participantCount});

  final String channelName;
  final int? participantCount;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 13, color: Colors.greenAccent),
                const SizedBox(width: 6),
                Text(channelName, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          if (participantCount != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '$participantCount',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
