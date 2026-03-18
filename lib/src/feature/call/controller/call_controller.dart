import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/src/feature/call/data/call_repository.dart';
import 'package:flutter_project/src/feature/call/models/call_event.dart';
import 'package:flutter_project/src/feature/call/models/call_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';

part 'call_controller.freezed.dart';

@freezed
sealed class CallState with _$CallState {
  const CallState._();

  const factory CallState.idle() = Call$IdleState;

  const factory CallState.joining({required String channelName, required CallType callType}) =
      Call$JoiningState;

  const factory CallState.connected({
    required String channelName,
    required CallType callType,
    required int localUid,
    required List<int> remoteUids,
    required bool isMuted,
    required bool isCameraOff,
  }) = Call$ConnectedState;

  const factory CallState.error(String message) = Call$ErrorState;

  bool get isInCall => this is Call$ConnectedState || this is Call$JoiningState;
}

/// Manages the Agora call lifecycle: initialize, join, leave, and local
/// media controls.
final class CallController extends StateController<CallState> with DroppableControllerHandler {
  CallController({
    required ICallRepository callRepository,
    required String appId,
    super.initialState = const CallState.idle(),
  }) : _callRepository = callRepository,
       _appId = appId;

  final ICallRepository _callRepository;
  final String _appId;
  StreamSubscription<CallEvent>? _eventsSubscription;

  /// Exposes the underlying engine for video view rendering.
  RtcEngine get engine => _callRepository.engine;

  /// Initializes the Agora engine. Called once from the config widget.
  void initialize() => handle(() async {
    await _callRepository.initialize(_appId);
    _eventsSubscription = _callRepository.events.listen(_onCallEvent);
  }, error: (e, st) async => setState(CallState.error('Initialization failed: $e')));

  void _onCallEvent(CallEvent event) {
    switch (event) {
      case CallEvent$Joined(:final localUid):
        final current = state;
        if (current is Call$JoiningState) {
          setState(
            CallState.connected(
              channelName: current.channelName,
              callType: current.callType,
              localUid: localUid,
              remoteUids: const [],
              isMuted: false,
              isCameraOff: false,
            ),
          );
        }
      case CallEvent$UserJoined(:final uid):
        _whenConnected((s) => s.copyWith(remoteUids: [...s.remoteUids, uid]));
      case CallEvent$UserLeft(:final uid):
        _whenConnected((s) => s.copyWith(remoteUids: s.remoteUids.where((u) => u != uid).toList()));
      case CallEvent$Error(:final message):
        setState(CallState.error(message));
    }
  }

  void _whenConnected(Call$ConnectedState Function(Call$ConnectedState) updater) {
    final current = state;
    if (current is Call$ConnectedState) setState(updater(current));
  }

  /// Joins a channel with the given parameters.
  void join({
    required String channelName,
    required CallType callType,
    required int uid,
    String? token,
  }) => handle(() async {
    if (_appId.isEmpty) {
      setState(
        const CallState.error(
          'Agora App ID is not configured. '
          'Add AGORA_APP_ID to your config file.',
        ),
      );
      return;
    }
    await _requestPermissions(callType);
    setState(CallState.joining(channelName: channelName, callType: callType));
    await _callRepository.joinChannel(
      channelName: channelName,
      token: token?.isNotEmpty == true ? token : null,
      uid: uid,
      callType: callType,
    );
  }, error: (e, st) async => setState(CallState.error(e.toString())));

  /// Leaves the current channel and returns to idle.
  void leave() => handle(() async {
    await _callRepository.leaveChannel();
    setState(const CallState.idle());
  }, error: (e, st) async => setState(const CallState.idle()));

  /// Toggles local microphone mute.
  void toggleMute() => handle(() async {
    final current = state;
    if (current is! Call$ConnectedState) return;
    final newMuted = !current.isMuted;
    await _callRepository.toggleMute(newMuted);
    setState(current.copyWith(isMuted: newMuted));
  });

  /// Toggles local camera on/off.
  void toggleCamera() => handle(() async {
    final current = state;
    if (current is! Call$ConnectedState) return;
    final newCameraOff = !current.isCameraOff;
    await _callRepository.toggleCamera(newCameraOff);
    setState(current.copyWith(isCameraOff: newCameraOff));
  });

  /// Switches between front and rear cameras.
  void switchCamera() => handle(() async {
    await _callRepository.switchCamera();
  });

  /// Resets error state and re-initializes the engine.
  void retryInit() {
    setState(const CallState.idle());
    initialize();
  }

  Future<void> _requestPermissions(CallType callType) async {
    if (kIsWeb) return;
    try {
      final permissions = <Permission>[Permission.microphone];
      if (callType == CallType.video) permissions.add(Permission.camera);
      await permissions.request();
    } on Exception catch (_) {
      // Some platforms don't support explicit permission requests; ignore.
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _callRepository.dispose();
    super.dispose();
  }
}
