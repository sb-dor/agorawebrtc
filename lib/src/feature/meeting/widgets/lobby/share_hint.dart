import 'package:flutter/material.dart';

/// Banner shown after a meeting code is generated, prompting the user to share it.
class ShareHint extends StatelessWidget {
  const ShareHint({super.key, required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.teal.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.share, size: 16, color: Colors.teal),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Share this code with people you want in the meeting.',
            style: TextStyle(color: Colors.teal, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: onCopy,
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Copy', style: TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}
