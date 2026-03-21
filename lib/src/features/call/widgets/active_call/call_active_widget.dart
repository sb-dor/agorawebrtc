import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/src/features/call/controller/call_controller.dart';
import 'package:flutter_project/src/features/call/controller/call_media_controller.dart';
import 'package:flutter_project/src/features/call/controller/call_members_controller.dart';
import 'package:flutter_project/src/features/call/models/call_type.dart';
import 'package:flutter_project/src/features/call/widgets/active_call/audio_call_view.dart';
import 'package:flutter_project/src/features/call/widgets/active_call/video_call_view.dart';
import 'package:flutter_project/src/features/call/widgets/call_screen.dart';

/// Active call screen — renders either [VideoCallView] or [AudioCallView]
/// based on the current call type, wiring state from all three controllers.
class CallActiveWidget extends StatefulWidget {
  const CallActiveWidget({super.key});

  @override
  State<CallActiveWidget> createState() => _CallActiveWidgetState();
}

class _CallActiveWidgetState extends State<CallActiveWidget> {
  late final _scope = CallConfigInhWidget.of(context);
  late final _callController = _scope.callController;
  late final _mediaController = _scope.callMediaController;
  late final _membersController = _scope.callMembersController;

  @override
  Widget build(BuildContext context) => StateConsumer<CallController, CallState>(
    controller: _callController,
    builder: (context, callState, _) {
      if (callState is! Call$ConnectedState) return const SizedBox.shrink();
      return SafeArea(
        child: StateConsumer<CallMembersController, CallMembersState>(
          controller: _membersController,
          builder: (context, membersState, _) {
            final activeMembers = membersState is CallMembers$ActiveState ? membersState : null;
            final remoteUids = activeMembers?.remoteUids ?? const <int>[];
            final remoteMutedAudio = activeMembers?.remoteMutedAudio ?? const <int, bool>{};
            final remoteCameraOff = activeMembers?.remoteCameraOff ?? const <int, bool>{};

            return StateConsumer<CallMediaController, CallMediaState>(
              controller: _mediaController,
              builder: (context, mediaState, _) {
                if (callState.callType == CallType.video) {
                  return VideoCallView(
                    callState: callState,
                    remoteUids: remoteUids,
                    mediaState: mediaState,
                    callController: _callController,
                    mediaController: _mediaController,
                    remoteMutedAudio: remoteMutedAudio,
                    remoteCameraOff: remoteCameraOff,
                  );
                }
                return AudioCallView(
                  callState: callState,
                  remoteUids: remoteUids,
                  mediaState: mediaState,
                  callController: _callController,
                  mediaController: _mediaController,
                  remoteMutedUids: remoteMutedAudio.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toSet(),
                );
              },
            );
          },
        ),
      );
    },
  );
}
