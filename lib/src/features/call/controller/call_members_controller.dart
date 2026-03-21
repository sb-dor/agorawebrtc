import 'dart:async';

import 'package:agorawebrtc/src/features/call/models/call_event.dart';
import 'package:control/control.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class CallMembersState {
  const CallMembersState();

  /// No active call — no participant data available.
  const factory CallMembersState.idle() = CallMembers$IdleState;

  /// Active call — local uid, list of remote uids, and remote media state.
  const factory CallMembersState.active({
    required int localUid,
    required List<int> remoteUids,
    required Map<int, bool> remoteMutedAudio,
    required Map<int, bool> remoteCameraOff,
  }) = CallMembers$ActiveState;
}

/// No active call — no participant data available.
final class CallMembers$IdleState extends CallMembersState {
  const CallMembers$IdleState();
}

/// Active call — local uid, list of remote uids, and per-user media state.
final class CallMembers$ActiveState extends CallMembersState {
  const CallMembers$ActiveState({
    required this.localUid,
    required this.remoteUids,
    required this.remoteMutedAudio,
    required this.remoteCameraOff,
  });

  final int localUid;
  final List<int> remoteUids;

  /// uid → true when the remote user has muted their microphone.
  final Map<int, bool> remoteMutedAudio;

  /// uid → true when the remote user has turned their camera off.
  final Map<int, bool> remoteCameraOff;

  CallMembers$ActiveState copyWith({
    int? localUid,
    List<int>? remoteUids,
    Map<int, bool>? remoteMutedAudio,
    Map<int, bool>? remoteCameraOff,
  }) => CallMembers$ActiveState(
    localUid: localUid ?? this.localUid,
    remoteUids: remoteUids ?? this.remoteUids,
    remoteMutedAudio: remoteMutedAudio ?? this.remoteMutedAudio,
    remoteCameraOff: remoteCameraOff ?? this.remoteCameraOff,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallMembers$ActiveState &&
          localUid == other.localUid &&
          remoteUids == other.remoteUids &&
          remoteMutedAudio == other.remoteMutedAudio &&
          remoteCameraOff == other.remoteCameraOff);

  @override
  int get hashCode =>
      localUid.hashCode ^
      remoteUids.hashCode ^
      remoteMutedAudio.hashCode ^
      remoteCameraOff.hashCode;

  @override
  String toString() =>
      'CallMembersState.active(localUid: $localUid, remoteUids: $remoteUids, '
      'remoteMutedAudio: $remoteMutedAudio, remoteCameraOff: $remoteCameraOff)';
}

/// Tracks who is in the call and their media state (mute/camera).
/// Subscribes directly to repository events — has no knowledge of call
/// lifecycle (join/leave) or local media controls.
class CallMembersController extends StateController<CallMembersState>
    with SequentialControllerHandler {
  CallMembersController({required final Stream<CallEvent> eventStream})
    : super(initialState: const CallMembersState.idle()) {
    _subscription = eventStream.listen(_onEvent);
  }

  StreamSubscription<CallEvent>? _subscription;

  void _onEvent(CallEvent event) {
    switch (event) {
      case CallEvent$Joined(:final localUid):
        setState(
          CallMembersState.active(
            localUid: localUid,
            remoteUids: const [],
            remoteMutedAudio: const {},
            remoteCameraOff: const {},
          ),
        );
      case CallEvent$Left():
        _subscription?.cancel();
        setState(const CallMembersState.idle());
      case CallEvent$UserJoined(:final uid):
        _whenActive((s) => s.copyWith(remoteUids: [...s.remoteUids, uid]));
      case CallEvent$UserLeft(:final uid):
        _whenActive(
          (s) => s.copyWith(
            remoteUids: s.remoteUids.where((u) => u != uid).toList(),
            remoteMutedAudio: Map.of(s.remoteMutedAudio)..remove(uid),
            remoteCameraOff: Map.of(s.remoteCameraOff)..remove(uid),
          ),
        );
      case CallEvent$UserMutedAudio(:final uid, :final muted):
        _whenActive((s) => s.copyWith(remoteMutedAudio: {...s.remoteMutedAudio, uid: muted}));
      case CallEvent$UserMutedVideo(:final uid, :final muted):
        _whenActive((s) => s.copyWith(remoteCameraOff: {...s.remoteCameraOff, uid: muted}));
      case CallEvent$Error():
        break; // handled by CallController
    }
  }

  void _whenActive(CallMembers$ActiveState Function(CallMembers$ActiveState) updater) {
    final current = state;
    if (current is CallMembers$ActiveState) setState(updater(current));
  }

  /// Resets to idle — called from the widget layer when a call ends.
  void reset() => setState(const CallMembersState.idle());

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
