import 'package:flutter/foundation.dart';

/// UI-state controller for the call lobby.
///
/// Tracks the last used channel name so the lobby can pre-fill the input
/// after a call ends.
class CallDataController with ChangeNotifier {
  String _lastChannelName = '';

  String get lastChannelName => _lastChannelName;

  void setLastChannelName(String name) {
    if (_lastChannelName == name) return;
    _lastChannelName = name;
    notifyListeners();
  }
}
