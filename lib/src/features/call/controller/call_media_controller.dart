import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/src/features/call/data/call_repository.dart';

/// Local media state — mute and camera flags.
@immutable
class CallMediaState {
  const CallMediaState({this.isMuted = false, this.isCameraOff = false});

  final bool isMuted;
  final bool isCameraOff;

  CallMediaState copyWith({bool? isMuted, bool? isCameraOff}) => CallMediaState(
    isMuted: isMuted ?? this.isMuted,
    isCameraOff: isCameraOff ?? this.isCameraOff,
  );
}

/// Manages local media controls: mute, camera on/off, and camera flip.
/// Has no knowledge of call lifecycle or participants.
class CallMediaController extends StateController<CallMediaState> with SequentialControllerHandler {
  CallMediaController({required ICallRepository callRepository})
    : _callRepository = callRepository,
      super(initialState: const CallMediaState());

  final ICallRepository _callRepository;

  void toggleMute() => handle(() async {
    final newMuted = !state.isMuted;
    await _callRepository.toggleMute(newMuted);
    setState(state.copyWith(isMuted: newMuted));
  });

  void toggleCamera() => handle(() async {
    final newCameraOff = !state.isCameraOff;
    await _callRepository.toggleCamera(newCameraOff);
    setState(state.copyWith(isCameraOff: newCameraOff));
  });

  void switchCamera() => handle(() async {
    await _callRepository.switchCamera();
  });

  /// Resets to defaults — called from the widget layer when a call ends.
  void reset() => setState(const CallMediaState());
}
