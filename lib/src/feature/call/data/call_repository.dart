import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_project/src/feature/call/models/call_event.dart';
import 'package:flutter_project/src/feature/call/models/call_type.dart';

/// Contract for managing Agora RTC engine operations.
abstract interface class ICallRepository {
  Future<void> initialize(String appId);

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

  RtcEngine get engine;

  Stream<CallEvent> get events;

  void dispose();
}

/// Agora RTC engine implementation of [ICallRepository].
final class CallRepositoryImpl implements ICallRepository {
  final StreamController<CallEvent> _streamController = StreamController<CallEvent>.broadcast();

  late final RtcEngine _engine;
  bool _initialized = false;

  @override
  RtcEngine get engine => _engine;

  @override
  Stream<CallEvent> get events => _streamController.stream;

  @override
  Future<void> initialize(String appId) async {
    if (_initialized) return;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _streamController.add(CallEvent$Joined(connection.localUid ?? 0));
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          _streamController.add(CallEvent$UserJoined(remoteUid));
        },
        onUserOffline: (connection, remoteUid, reason) {
          _streamController.add(CallEvent$UserLeft(remoteUid));
        },
        onError: (err, msg) {
          _streamController.add(CallEvent$Error(msg));
        },
      ),
    );
    _initialized = true;
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

  @override
  void dispose() {
    _engine
      ..unregisterEventHandler(const RtcEngineEventHandler())
      ..release();
    _streamController.close();
  }
}
