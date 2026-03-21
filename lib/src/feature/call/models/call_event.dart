import 'package:flutter/foundation.dart';

/// Base class for Agora RTC engine events.
@immutable
sealed class CallEvent {
  const CallEvent();
}

/// Fired when the local user successfully joins the channel.
final class CallEvent$Joined extends CallEvent {
  const CallEvent$Joined(this.localUid);

  final int localUid;
}

/// Fired when the local user leaves the channel.
final class CallEvent$Left extends CallEvent {
  const CallEvent$Left(this.localUid);

  final int localUid;
}

/// Fired when a remote user joins the channel.
final class CallEvent$UserJoined extends CallEvent {
  const CallEvent$UserJoined(this.uid);

  final int uid;
}

/// Fired when a remote user leaves the channel.
final class CallEvent$UserLeft extends CallEvent {
  const CallEvent$UserLeft(this.uid);

  final int uid;
}

/// Fired when Agora reports an engine-level error.
final class CallEvent$Error extends CallEvent {
  const CallEvent$Error(this.message);

  final String message;
}

/// Fired when a remote user mutes or unmutes their microphone.
final class CallEvent$UserMutedAudio extends CallEvent {
  const CallEvent$UserMutedAudio(this.uid, this.muted);

  final int uid;
  final bool muted;
}

/// Fired when a remote user stops or resumes publishing their video stream.
final class CallEvent$UserMutedVideo extends CallEvent {
  const CallEvent$UserMutedVideo(this.uid, this.muted);

  final int uid;
  final bool muted;
}
