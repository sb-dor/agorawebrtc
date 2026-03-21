import 'package:flutter/material.dart';

/// Placeholder shown for unfilled grid slots (e.g. 3 people in a 2×2 grid).
class EmptySlotTile extends StatelessWidget {
  const EmptySlotTile({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF111827),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add_outlined, size: 28, color: Colors.white12),
          SizedBox(height: 6),
          Text('Empty', style: TextStyle(color: Colors.white12, fontSize: 10)),
        ],
      ),
    ),
  );
}
