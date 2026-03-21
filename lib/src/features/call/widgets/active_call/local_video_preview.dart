import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

/// Small rounded preview of the local camera feed (bottom-right corner).
class LocalVideoPreview extends StatelessWidget {
  const LocalVideoPreview({super.key, required this.engine});

  final RtcEngine engine;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: AgoraVideoView(
      controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
    ),
  );
}
