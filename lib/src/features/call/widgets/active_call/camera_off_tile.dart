import 'package:flutter/material.dart';

/// Shown inside a participant tile when that participant's camera is off.
class CameraOffTile extends StatelessWidget {
  const CameraOffTile({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF1C2333),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.teal.shade700,
          child: Text(
            label.isNotEmpty ? label[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        const Icon(Icons.videocam_off, size: 14, color: Colors.white38),
      ],
    ),
  );
}
