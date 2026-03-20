import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/src/feature/call/controller/call_controller.dart';
import 'package:flutter_project/src/feature/call/controller/call_media_controller.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/call_control_bar.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/call_top_bar.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/local_video_preview.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/participant_grid.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/waiting_view.dart';
import 'package:flutter_project/src/feature/call/widgets/call_screen.dart';

/// Full-screen video call layout.
///
/// - 0–1 remotes: classic Stack overlay with local preview in the corner.
///   Tapping the corner preview swaps it with the main view (WhatsApp-style).
/// - 2+ remotes: Column layout with [ParticipantGrid] filling the centre.
class VideoCallView extends StatefulWidget {
  const VideoCallView({
    super.key,
    required this.callState,
    required this.remoteUids,
    required this.mediaState,
    required this.callController,
    required this.mediaController,
  });

  final Call$ConnectedState callState;
  final List<int> remoteUids;
  final CallMediaState mediaState;
  final CallController callController;
  final CallMediaController mediaController;

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  late final RtcEngine _rtcEngine;

  /// When true the local feed is full-screen and the remote is in the corner.
  bool _isSwapped = false;

  @override
  void initState() {
    super.initState();
    _rtcEngine = CallConfigInhWidget.of(context).rtcEngine;
  }

  @override
  void didUpdateWidget(VideoCallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the remote participant left while swapped, return to the default layout.
    if (_isSwapped && widget.remoteUids.isEmpty) {
      _isSwapped = false;
    }
  }

  void _toggleSwap() => setState(() => _isSwapped = !_isSwapped);

  @override
  Widget build(BuildContext context) {
    final remoteCount = widget.remoteUids.length;

    if (remoteCount >= 2) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              CallTopBar(
                channelName: widget.callState.channelName,
                participantCount: remoteCount + 1,
              ),
              Expanded(
                child: ParticipantGrid(
                  remoteUids: widget.remoteUids,
                  channelName: widget.callState.channelName,
                  engine: _rtcEngine,
                  isCameraOff: widget.mediaState.isCameraOff,
                ),
              ),
              CallControlBar(
                callType: widget.callState.callType,
                mediaState: widget.mediaState,
                callController: widget.callController,
                mediaController: widget.mediaController,
                overlay: false,
              ),
            ],
          ),
        ),
      );
    }

    // ── 0 or 1 remote: Stack overlay layout ─────────────────────────────────
    final hasRemote = remoteCount == 1;
    final remoteUid = hasRemote ? widget.remoteUids.first : null;

    // Whether the swap is currently active (only meaningful when there's a remote).
    final swapped = _isSwapped && hasRemote;

    // Full-screen (background) view.
    final mainView = swapped
        ? AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _rtcEngine,
              canvas: const VideoCanvas(uid: 0),
            ),
          )
        : hasRemote
        ? AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _rtcEngine,
              canvas: VideoCanvas(uid: remoteUid!),
              connection: RtcConnection(channelId: widget.callState.channelName),
            ),
          )
        : const WaitingView();

    // Corner (small) view — shown only when swapping is possible or camera is on.
    Widget? cornerChild;
    if (swapped) {
      // Remote participant in the corner.
      cornerChild = AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _rtcEngine,
          canvas: VideoCanvas(uid: remoteUid!),
          connection: RtcConnection(channelId: widget.callState.channelName),
        ),
      );
    } else if (!widget.mediaState.isCameraOff) {
      // Local camera in the corner.
      cornerChild = LocalVideoPreview(engine: _rtcEngine);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          mainView,

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CallTopBar(
              channelName: widget.callState.channelName,
              participantCount: remoteCount + 1,
            ),
          ),

          // Corner preview — tappable to swap views.
          if (cornerChild != null)
            Positioned(
              right: 16,
              bottom: 104,
              width: 96,
              height: 128,
              child: GestureDetector(
                onTap: hasRemote ? _toggleSwap : null,
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: cornerChild),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CallControlBar(
              callType: widget.callState.callType,
              mediaState: widget.mediaState,
              callController: widget.callController,
              mediaController: widget.mediaController,
            ),
          ),
        ],
      ),
    );
  }
}
