import 'dart:async';
import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/src/feature/call/data/call_repository.dart';
import 'package:flutter_project/src/feature/call/models/call_event.dart';

@immutable
sealed class CallMembersState {
  const CallMembersState();

  /// No active call — no participant data available.
  const factory CallMembersState.idle() = CallMembers$IdleState;

  /// Active call — local uid and list of remote uids.
  const factory CallMembersState.active({required int localUid, required List<int> remoteUids}) =
      CallMembers$ActiveState;
}

/// No active call — no participant data available.
final class CallMembers$IdleState extends CallMembersState {
  const CallMembers$IdleState();
}

/// Active call — local uid and list of remote uids.
final class CallMembers$ActiveState extends CallMembersState {
  const CallMembers$ActiveState({required this.localUid, required this.remoteUids});

  final int localUid;
  final List<int> remoteUids;

  CallMembers$ActiveState copyWith({int? localUid, List<int>? remoteUids}) =>
      CallMembers$ActiveState(
        localUid: localUid ?? this.localUid,
        remoteUids: remoteUids ?? this.remoteUids,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallMembers$ActiveState &&
          localUid == other.localUid &&
          remoteUids == other.remoteUids);

  @override
  int get hashCode => localUid.hashCode ^ remoteUids.hashCode;

  @override
  String toString() => 'CallMembersState.active(localUid: $localUid, remoteUids: $remoteUids)';
}

/// Tracks who is in the call: the local user and all remote participants.
/// Subscribes directly to repository events — has no knowledge of call
/// lifecycle (join/leave) or media controls.
final class CallMembersController extends StateController<CallMembersState>
    with SequentialControllerHandler {
  CallMembersController({required ICallRepository callRepository})
    : _callRepository = callRepository,
      super(initialState: const CallMembersState.idle()) {
    _subscription = _callRepository.onCallEvents().listen(_onEvent);
  }

  final ICallRepository _callRepository;
  StreamSubscription<CallEvent>? _subscription;

  void _onEvent(CallEvent event) {
    switch (event) {
      case CallEvent$Joined(:final localUid):
        setState(CallMembersState.active(localUid: localUid, remoteUids: const []));
      case CallEvent$Left():
        _subscription?.cancel();
        setState(const CallMembersState.idle());
      case CallEvent$UserJoined(:final uid):
        _whenActive((s) => s.copyWith(remoteUids: [...s.remoteUids, uid]));
      case CallEvent$UserLeft(:final uid):
        _whenActive((s) => s.copyWith(remoteUids: s.remoteUids.where((u) => u != uid).toList()));
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
