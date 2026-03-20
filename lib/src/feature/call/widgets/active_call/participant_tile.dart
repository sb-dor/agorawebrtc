import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/camera_off_tile.dart';

/// A single participant tile in the grid — shows video feed or camera-off placeholder.
class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.uid,
    required this.channelName,
    required this.engine,
    required this.isLocal,
    required this.cameraOff,
  });

  final int uid;
  final String channelName;
  final RtcEngine engine;
  final bool isLocal;
  final bool cameraOff;

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
