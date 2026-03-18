import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/src/feature/call/controller/call_controller.dart';
import 'package:flutter_project/src/feature/call/models/call_type.dart';
import 'package:flutter_project/src/feature/call/widgets/call_config_widget.dart';

/// Active call screen — renders either video or audio UI based on call type.
class CallActiveWidget extends StatefulWidget {
  const CallActiveWidget({super.key});

  @override
  State<CallActiveWidget> createState() => _CallActiveWidgetState();
}

class _CallActiveWidgetState extends State<CallActiveWidget> {
  late final _scope = CallConfigInhWidget.of(context);
  late final _controller = _scope.callController;

  @override
  Widget build(BuildContext context) => StateConsumer<CallController, CallState>(
    controller: _controller,
    builder: (context, state, _) {
      if (state is! Call$ConnectedState) return const SizedBox.shrink();
      return state.callType == CallType.video
          ? _VideoCallView(state: state, controller: _controller)
          : _AudioCallView(state: state, controller: _controller);
    },
  );
}

// ── Video call ──────────────────────────────────────────────────────────────

class _VideoCallView extends StatelessWidget {
  const _VideoCallView({required this.state, required this.controller});

  final Call$ConnectedState state;
  final CallController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      fit: StackFit.expand,
      children: [
        // Remote video grid or waiting placeholder
        if (state.remoteUids.isNotEmpty)
          _RemoteVideoGrid(
            remoteUids: state.remoteUids,
            channelName: state.channelName,
            engine: controller.engine,
          )
        else
          const _WaitingView(),

        // Top overlay: channel name + participant count
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopBar(
            channelName: state.channelName,
            participantCount: state.remoteUids.length + 1,
          ),
        ),

        // Local video preview (bottom-right corner)
        if (!state.isCameraOff)
          Positioned(
            right: 16,
            bottom: 104,
            width: 96,
            height: 128,
            child: _LocalVideoPreview(engine: controller.engine),
          ),

        // Bottom control bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _ControlBar(state: state, controller: controller),
        ),
      ],
    ),
  );
}

// ── Audio call ──────────────────────────────────────────────────────────────

class _AudioCallView extends StatelessWidget {
  const _AudioCallView({required this.state, required this.controller});

  final Call$ConnectedState state;
  final CallController controller;

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
                _ParticipantAvatars(remoteUids: state.remoteUids),
                const SizedBox(height: 24),
                Text(
                  state.channelName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.remoteUids.isEmpty
                      ? 'Waiting for others to join…'
                      : '${state.remoteUids.length} '
                            'participant${state.remoteUids.length == 1 ? '' : 's'} connected',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _TopBar(channelName: state.channelName)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _ControlBar(state: state, controller: controller),
          ),
        ],
      ),
    ),
  );
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.channelName});

  final String channelName;

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
        ],
      ),
    ),
  );
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.state, required this.controller});

  final Call$ConnectedState state;
  final CallController controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: state.isMuted ? Icons.mic_off : Icons.mic,
          label: state.isMuted ? 'Unmute' : 'Mute',
          active: state.isMuted,
          onTap: controller.toggleMute,
        ),
        if (state.callType == CallType.video) ...[
          _ControlButton(
            icon: state.isCameraOff ? Icons.videocam_off : Icons.videocam,
            label: state.isCameraOff ? 'Start Cam' : 'Stop Cam',
            active: state.isCameraOff,
            onTap: controller.toggleCamera,
          ),
          _ControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: controller.switchCamera,
          ),
        ],
        _ControlButton(
          icon: Icons.call_end,
          label: 'End',
          onTap: controller.leave,
          backgroundColor: Colors.redAccent,
        ),
      ],
    ),
  );
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                backgroundColor ?? (active ? Colors.orange.withValues(alpha: 0.8) : Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    ),
  );
}

class _RemoteVideoView extends StatelessWidget {
  const _RemoteVideoView({required this.uid, required this.channelName, required this.engine});

  final int uid;
  final String channelName;
  final RtcEngine engine;

  @override
  Widget build(BuildContext context) => AgoraVideoView(
    controller: VideoViewController.remote(
      rtcEngine: engine,
      canvas: VideoCanvas(uid: uid),
      connection: RtcConnection(channelId: channelName),
    ),
  );
}

class _LocalVideoPreview extends StatelessWidget {
  const _LocalVideoPreview({required this.engine});

  final RtcEngine engine;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: AgoraVideoView(
      controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
    ),
  );
}

class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_search, size: 72, color: Colors.white24),
        SizedBox(height: 16),
        Text('Waiting for others to join…', style: TextStyle(color: Colors.white54, fontSize: 16)),
      ],
    ),
  );
}

class _ParticipantAvatars extends StatelessWidget {
  const _ParticipantAvatars({required this.remoteUids});

  final List<int> remoteUids;

  @override
  Widget build(BuildContext context) {
    if (remoteUids.isEmpty) {
      return const CircleAvatar(
        radius: 60,
        backgroundColor: Colors.white12,
        child: Icon(Icons.person, size: 60, color: Colors.white38),
      );
    }
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: remoteUids
          .map(
            (uid) => CircleAvatar(
              radius: 48,
              backgroundColor: Colors.teal.shade700,
              child: Text(
                'U${uid % 100}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
