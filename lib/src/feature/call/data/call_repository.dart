import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_project/src/feature/call/models/call_event.dart';
import 'package:flutter_project/src/feature/call/models/call_type.dart';
import 'package:l/l.dart';

/// Contract for managing Agora RTC engine operations.
abstract interface class ICallRepository {
  Stream<CallEvent> onCallEvents();

  Future<void> joinChannel({
    required String channelName,
    required String? token,
    required int uid,
    required CallType callType,
  });

  Future<void> leaveChannel();

  Future<void> toggleMute(bool mute);

  Future<void> toggleCamera(bool disable);

  Future<void> switchCamera();
}

/// Agora RTC engine implementation of [ICallRepository].
final class CallRepositoryImpl implements ICallRepository {
  CallRepositoryImpl(this._engine);

  final RtcEngine _engine;

  @override
  Stream<CallEvent> onCallEvents() {
    // ignore: close_sinks — closed implicitly when the engine handler is unregistered
    final streamController = StreamController<CallEvent>();

    Future<void> initialize() async {
      if (streamController.isClosed) return;
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            streamController.add(CallEvent$Joined(connection.localUid ?? 0));
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            streamController.add(CallEvent$UserJoined(remoteUid));
          },
          onUserOffline: (connection, remoteUid, reason) {
            streamController.add(CallEvent$UserLeft(remoteUid));
          },
          onError: (err, msg) {
            l.e('error $err');
            streamController.add(CallEvent$Error(err.toString()));
          },
          onLeaveChannel: (connection, elapsed) {
            if (!streamController.isClosed) {
              streamController
                ..add(CallEvent$Left(connection.localUid ?? 0))
                ..close();
            }
          },
        ),
      );
    }

    initialize();

    return streamController.stream;
  }

  @override
  Future<void> joinChannel({
    required String channelName,
    required String? token,
    required int uid,
    required CallType callType,
  }) async {
    final options = ChannelMediaOptions(
      channelProfile: ChannelProfileType.channelProfileCommunication,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      publishCameraTrack: callType == CallType.video,
      publishMicrophoneTrack: true,
      autoSubscribeAudio: true,
      autoSubscribeVideo: callType == CallType.video,
    );
    if (callType == CallType.video) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.disableVideo();
    }
    await _engine.joinChannel(
      token: token ?? '',
      channelId: channelName,
      uid: uid,
      options: options,
    );
  }

  @override
  Future<void> leaveChannel() => _engine.leaveChannel();

  @override
  Future<void> toggleMute(bool mute) => _engine.muteLocalAudioStream(mute);

  @override
  Future<void> toggleCamera(bool disable) async {
    await _engine.muteLocalVideoStream(disable);
    if (disable) {
      await _engine.stopPreview();
    } else {
      await _engine.startPreview();
    }
  }

  @override
  Future<void> switchCamera() => _engine.switchCamera();
}
