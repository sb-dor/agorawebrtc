import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/src/feature/call/models/call_event.dart';
import 'package:flutter_project/src/feature/call/data/call_repository.dart';
import 'package:flutter_project/src/feature/call/models/call_type.dart';
import 'package:permission_handler/permission_handler.dart';

@immutable
sealed class CallState {
  const CallState();

  const factory CallState.idle() = Call$IdleState;

  const factory CallState.joining({required String channelName, required CallType callType}) =
      Call$JoiningState;

  const factory CallState.connected({
    required String channelName,
    required CallType callType,
    required int localUid,
  }) = Call$ConnectedState;

  const factory CallState.error(String message) = Call$ErrorState;

  bool get isInCall => this is Call$ConnectedState || this is Call$JoiningState;
}

final class Call$IdleState extends CallState {
  const Call$IdleState();
}

final class Call$JoiningState extends CallState {
  const Call$JoiningState({required this.channelName, required this.callType});

  final String channelName;
  final CallType callType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Call$JoiningState &&
          channelName == other.channelName &&
          callType == other.callType);

  @override
  int get hashCode => channelName.hashCode ^ callType.hashCode;

  @override
  String toString() => 'CallState.joining(channelName: $channelName, callType: $callType)';
}

final class Call$ConnectedState extends CallState {
  const Call$ConnectedState({
    required this.channelName,
    required this.callType,
    required this.localUid,
  });

  final String channelName;
  final CallType callType;
  final int localUid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Call$ConnectedState &&
          channelName == other.channelName &&
          callType == other.callType &&
          localUid == other.localUid);

  @override
  int get hashCode => channelName.hashCode ^ callType.hashCode ^ localUid.hashCode;

  @override
  String toString() =>
      'CallState.connected(channelName: $channelName, callType: $callType, localUid: $localUid)';
}

final class Call$ErrorState extends CallState {
  const Call$ErrorState(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Call$ErrorState && message == other.message);

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'CallState.error(message: $message)';
}

/// Manages the call lifecycle: join, leave, and error recovery.
/// Media controls and participant tracking are handled by dedicated controllers.
final class CallController extends StateController<CallState> with SequentialControllerHandler {
  CallController({
    required ICallRepository callRepository,
    super.initialState = const CallState.idle(),
  }) : _callRepository = callRepository {
    _eventsSubscription = _callRepository.onCallEvents().listen(_onCallEvent);
  }

  final ICallRepository _callRepository;
  StreamSubscription<CallEvent>? _eventsSubscription;

  /// Exposes the underlying engine for video view rendering.
  // ignore: deprecated_member_use_from_same_package
  // ignore: invalid_use_of_visible_for_testing_member
  // Access via CallConfigInhWidget.of(context).rtcEngine instead where possible.

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
            ),
          );
        }
      case CallEvent$Error(:final message):
        setState(CallState.error(message));
      case CallEvent$UserJoined() || CallEvent$UserLeft():
        break; // handled by CallMembersController
    }
  }

  /// Joins a channel with the supplied [token] (null = no-token mode).
  void join({
    required String channelName,
    required CallType callType,
    required int uid,
    String? token,
  }) => handle(
    () async {
      await _requestPermissions(callType);
      setState(CallState.joining(channelName: channelName, callType: callType));
      await _callRepository.joinChannel(
        channelName: channelName,
        token: token,
        uid: uid,
        callType: callType,
      );
    },
    error: (e, st) async => setState(CallState.error(e.toString())),
  );

  /// Leaves the current channel and returns to idle.
  void leave() => handle(
    () async {
      await _callRepository.leaveChannel();
      setState(const CallState.idle());
    },
    error: (e, st) async => setState(const CallState.idle()),
  );

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
    super.dispose();
  }
}
