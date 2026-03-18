import 'package:flutter/material.dart';

/// Type of call.
enum CallType {
  audio,
  video;

  String get displayName => switch (this) {
    CallType.audio => 'Audio Call',
    CallType.video => 'Video Call',
  };

  IconData get icon => switch (this) {
    CallType.audio => Icons.call,
    CallType.video => Icons.videocam,
  };
}
