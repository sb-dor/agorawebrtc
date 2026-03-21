import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agorawebrtc/src/features/call/widgets/active_call/camera_off_tile.dart';
import 'package:flutter/material.dart';

/// A single participant tile in the grid — shows video feed or camera-off placeholder.
class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.uid,
    required this.channelName,
    required this.engine,
    required this.isLocal,
    required this.cameraOff,
    required this.audioMuted,
  });

  final int uid;
  final String channelName;
  final RtcEngine engine;
  final bool isLocal;
  final bool cameraOff;
  final bool audioMuted;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (cameraOff)
        CameraOffTile(label: isLocal ? 'You' : 'U${uid % 1000}')
      else if (isLocal)
        AgoraVideoView(
          controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
        )
      else
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: channelName),
          ),
        ),

      // Mic-off icon overlay — top-right corner
      if (audioMuted)
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.mic_off, color: Colors.white, size: 16),
          ),
        ),

      // Name label at the bottom of each tile
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          color: Colors.black54,
          child: Text(
            isLocal ? 'You' : 'User ${uid % 1000}',
            style: const TextStyle(color: Colors.white, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
  );
}
