import 'package:flutter_project/src/features/call/models/call_type.dart';

/// Parameters passed from the meeting lobby to the call screen.
class MeetingParams {
  const MeetingParams({
    required this.channelName,
    required this.callType,
    required this.uid,
    this.token,
  });

  final String channelName;
  final CallType callType;
  final int uid;

  /// Pre-generated RTC token. Null when running without App Certificate.
  final String? token;
}
