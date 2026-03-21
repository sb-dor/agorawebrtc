import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/src/features/call/models/call_type.dart';
import 'package:flutter_project/src/features/meeting/data/token_repository.dart';
import 'package:flutter_project/src/features/meeting/models/meeting_params.dart';

@immutable
sealed class MeetingState {
  const MeetingState();

  const factory MeetingState.idle() = Meeting$IdleState;

  const factory MeetingState.preparing({required CallType callType}) = Meeting$PreparingState;

  const factory MeetingState.ready(MeetingParams params) = Meeting$ReadyState;

  const factory MeetingState.error(String message) = Meeting$ErrorState;
}

final class Meeting$IdleState extends MeetingState {
  const Meeting$IdleState();
}

final class Meeting$PreparingState extends MeetingState {
  const Meeting$PreparingState({required this.callType});

  final CallType callType;
}

final class Meeting$ReadyState extends MeetingState {
  const Meeting$ReadyState(this.params);

  final MeetingParams params;
}

final class Meeting$ErrorState extends MeetingState {
  const Meeting$ErrorState(this.message);

  final String message;
}

/// Prepares a call by generating a token and building [MeetingParams].
/// The widget layer listens via [addListener] and navigates when state is [Meeting$ReadyState].
final class MeetingController extends StateController<MeetingState>
    with DroppableControllerHandler {
  MeetingController({required ITokenRepository tokenRepository})
    : _tokenRepository = tokenRepository,
      super(initialState: const MeetingState.idle());

  final ITokenRepository _tokenRepository;

  /// Generates a token for [channelName] then transitions to [Meeting$ReadyState].
  /// If [tempToken] is non-empty it is used directly, skipping generation.
  void prepare({
    required String channelName,
    required CallType callType,
    required int uid,
    String? tempToken,
  }) => handle(() async {
    setState(MeetingState.preparing(callType: callType));

    final token = (tempToken != null && tempToken.isNotEmpty)
        ? tempToken
        : await _tokenRepository.generateToken(channelName: channelName, uid: uid);

    setState(
      MeetingState.ready(
        MeetingParams(channelName: channelName, callType: callType, uid: uid, token: token),
      ),
    );
  }, error: (e, st) async => setState(MeetingState.error(e.toString())));

  /// Returns to idle — called from the widget layer after navigation completes
  /// or after an error is shown.
  void reset() => setState(const MeetingState.idle());
}
