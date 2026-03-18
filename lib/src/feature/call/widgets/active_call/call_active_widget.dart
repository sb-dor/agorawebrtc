import 'dart:math' as math;

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
  Widget build(BuildContext context) =>
      StateConsumer<CallController, CallState>(
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
  Widget build(BuildContext context) {
    final remoteCount = state.remoteUids.length;

    // 2+ remotes: structured Column so the local tile is included in the grid
    // and empty slots get a nice placeholder.
    if (remoteCount >= 2) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                channelName: state.channelName,
                participantCount: remoteCount + 1,
              ),
              Expanded(
                child: _ParticipantGrid(
                  remoteUids: state.remoteUids,
                  channelName: state.channelName,
                  engine: controller.engine,
                  isCameraOff: state.isCameraOff,
                ),
              ),
              _ControlBar(
                state: state,
                controller: controller,
                overlay: false,
              ),
            ],
          ),
        ),
      );
    }

    // 0 or 1 remote: Stack overlay layout (classic 1-on-1 experience).
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (remoteCount == 1)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: controller.engine,
                canvas: VideoCanvas(uid: state.remoteUids.first),
                connection: RtcConnection(channelId: state.channelName),
              ),
            )
          else
            const _WaitingView(),

          // Top overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              channelName: state.channelName,
              participantCount: remoteCount + 1,
            ),
          ),

          // Local preview (bottom-right corner)
          if (!state.isCameraOff)
            Positioned(
              right: 16,
              bottom: 104,
              width: 96,
              height: 128,
              child: _LocalVideoPreview(engine: controller.engine),
            ),

          // Control bar overlay
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
}

// ── Participant grid (3+ people) ────────────────────────────────────────────

/// Grid showing every participant including the local user.
/// Empty slots (when total doesn't fill the grid evenly) show a
/// tasteful placeholder instead of blank space.
class _ParticipantGrid extends StatelessWidget {
  const _ParticipantGrid({
    required this.remoteUids,
    required this.channelName,
    required this.engine,
    required this.isCameraOff,
  });

  final List<int> remoteUids;
  final String channelName;
  final RtcEngine engine;
  final bool isCameraOff;

  @override
  Widget build(BuildContext context) {
    // Local user (uid 0) is always first so the creator is always visible.
    final allUids = [0, ...remoteUids];
    final count = allUids.length;
    final crossAxisCount = count <= 4 ? 2 : 3;
    final rows = (count / crossAxisCount).ceil();
    final capacity = rows * crossAxisCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW =
            (constraints.maxWidth - (crossAxisCount - 1) * 2) / crossAxisCount;
        final cellH = (constraints.maxHeight - (rows - 1) * 2) / rows;
        final aspectRatio = cellW / math.max(cellH, 1);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: capacity,
          itemBuilder: (context, index) {
            if (index >= count) return const _EmptySlotTile();
            final uid = allUids[index];
            final isLocal = uid == 0;
            final cameraOff = isLocal && isCameraOff;
            return _ParticipantTile(
              uid: uid,
              channelName: channelName,
              engine: engine,
              isLocal: isLocal,
              cameraOff: cameraOff,
            );
          },
        );
      },
    );
  }
}

/// A single participant tile — video feed or camera-off placeholder.
class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
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
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video or camera-off placeholder
        if (cameraOff)
          _CameraOffTile(label: isLocal ? 'You' : 'U${uid % 1000}')
        else if (isLocal)
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(uid: 0),
            ),
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
}

/// Shown when a participant has their camera turned off.
class _CameraOffTile extends StatelessWidget {
  const _CameraOffTile({required this.label});

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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.videocam_off, size: 14, color: Colors.white38),
          ],
        ),
      );
}

/// Placeholder shown for unfilled grid slots (e.g. 3 people in a 2×2 grid).
class _EmptySlotTile extends StatelessWidget {
  const _EmptySlotTile();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF111827),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_outlined, size: 28, color: Colors.white12),
              SizedBox(height: 6),
              Text(
                'Empty',
                style: TextStyle(color: Colors.white12, fontSize: 10),
              ),
            ],
          ),
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
                          : '${state.remoteUids.length + 1} participants connected',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopBar(
                  channelName: state.channelName,
                  participantCount: state.remoteUids.length + 1,
                ),
              ),
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
  const _TopBar({required this.channelName, this.participantCount});

  final String channelName;
  final int? participantCount;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 13, color: Colors.greenAccent),
                    const SizedBox(width: 6),
                    Text(
                      channelName,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (participantCount != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '$participantCount',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.state,
    required this.controller,
    this.overlay = true,
  });

  final Call$ConnectedState state;
  final CallController controller;

  /// When [overlay] is true the bar floats over video (gradient background).
  /// When false it sits in a Column with a solid background.
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
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                )
              : null,
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
                color: backgroundColor ??
                    (active
                        ? Colors.orange.withValues(alpha: 0.8)
                        : Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
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
          controller: VideoViewController(
            rtcEngine: engine,
            canvas: const VideoCanvas(uid: 0),
          ),
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
            Text(
              'Waiting for others to join…',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
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
