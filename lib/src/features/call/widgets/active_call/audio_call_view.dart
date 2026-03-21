import 'package:agorawebrtc/src/features/call/controller/call_controller.dart';
import 'package:agorawebrtc/src/features/call/controller/call_media_controller.dart';
import 'package:agorawebrtc/src/features/call/widgets/active_call/call_control_bar.dart';
import 'package:agorawebrtc/src/features/call/widgets/active_call/call_top_bar.dart';
import 'package:agorawebrtc/src/features/call/widgets/active_call/participant_avatars.dart';
import 'package:flutter/material.dart';

/// Full-screen audio-only call layout with participant avatars.
class AudioCallView extends StatelessWidget {
  const AudioCallView({
    super.key,
    required this.callState,
    required this.remoteUids,
    required this.mediaState,
    required this.callController,
    required this.mediaController,
    required this.remoteMutedUids,
  });

  final Call$ConnectedState callState;
  final List<int> remoteUids;
  final CallMediaState mediaState;
  final CallController callController;
  final CallMediaController mediaController;

  /// UIDs of remote participants who have muted their microphone.
  final Set<int> remoteMutedUids;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F1520),
    body: SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ParticipantAvatars(remoteUids: remoteUids, mutedUids: remoteMutedUids),
                const SizedBox(height: 24),
                Text(
                  callState.channelName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  remoteUids.isEmpty
                      ? 'Waiting for others to join…'
                      : '${remoteUids.length + 1} participants connected',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CallTopBar(
              channelName: callState.channelName,
              participantCount: remoteUids.length + 1,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CallControlBar(
              callType: callState.callType,
              mediaState: mediaState,
              callController: callController,
              mediaController: mediaController,
            ),
          ),
        ],
      ),
    ),
  );
}
