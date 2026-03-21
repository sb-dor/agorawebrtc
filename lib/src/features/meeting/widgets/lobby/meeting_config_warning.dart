import 'package:flutter/material.dart';

/// Warning banner shown when AGORA_APP_ID is not set in the config file.
class MeetingConfigWarning extends StatelessWidget {
  const MeetingConfigWarning({super.key});

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.orange.shade900.withValues(alpha: 0.4),
    child: const Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Agora App ID not configured. '
              'Set AGORA_APP_ID in your config file.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    ),
  );
}
