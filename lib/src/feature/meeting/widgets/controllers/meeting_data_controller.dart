import 'package:flutter/foundation.dart';

/// UI-state controller for the meeting lobby.
///
/// Tracks the last used channel name so the lobby can pre-fill the input
/// on next visit.
class MeetingDataController with ChangeNotifier {
  String _lastChannelName = '';

  String get lastChannelName => _lastChannelName;

  void setLastChannelName(String name) {
    if (_lastChannelName == name) return;
    _lastChannelName = name;
    notifyListeners();
  }
}
