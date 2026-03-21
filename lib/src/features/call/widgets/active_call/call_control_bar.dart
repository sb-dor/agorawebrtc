import 'package:flutter/material.dart';
import 'package:flutter_project/src/features/call/controller/call_controller.dart';
import 'package:flutter_project/src/features/call/controller/call_media_controller.dart';
import 'package:flutter_project/src/features/call/models/call_type.dart';
import 'package:flutter_project/src/features/call/widgets/active_call/call_control_button.dart';

/// Bottom bar with mute, camera, flip and end-call controls.
///
/// Set [overlay] to `true` when the bar floats over video (gradient bg),
/// or `false` when it sits inside a Column (solid bg).
class CallControlBar extends StatelessWidget {
  const CallControlBar({
    super.key,
    required this.callType,
    required this.mediaState,
    required this.callController,
    required this.mediaController,
    this.overlay = true,
  });

  final CallType callType;
  final CallMediaState mediaState;
  final CallController callController;
  final CallMediaController mediaController;
  final bool overlay;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
    decoration: BoxDecoration(
      color: overlay ? null : const Color(0xFF0A0A0F),
      gradient: overlay
          ? LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
            )
          : null,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallControlButton(
          icon: mediaState.isMuted ? Icons.mic_off : Icons.mic,
          label: mediaState.isMuted ? 'Unmute' : 'Mute',
          active: mediaState.isMuted,
          onTap: mediaController.toggleMute,
        ),
        if (callType == CallType.video) ...[
          CallControlButton(
            icon: mediaState.isCameraOff ? Icons.videocam_off : Icons.videocam,
            label: mediaState.isCameraOff ? 'Start Cam' : 'Stop Cam',
            active: mediaState.isCameraOff,
            onTap: mediaController.toggleCamera,
          ),
          CallControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: mediaController.switchCamera,
          ),
        ],
        CallControlButton(
          icon: Icons.call_end,
          label: 'End',
          onTap: callController.leave,
          backgroundColor: Colors.redAccent,
        ),
      ],
    ),
  );
}
