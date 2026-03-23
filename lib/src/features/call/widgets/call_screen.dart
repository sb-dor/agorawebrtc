import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agorawebrtc/src/common/constant/config.dart';
import 'package:agorawebrtc/src/features/call/controller/call_controller.dart';
import 'package:agorawebrtc/src/features/call/controller/call_media_controller.dart';
import 'package:agorawebrtc/src/features/call/controller/call_members_controller.dart';
import 'package:agorawebrtc/src/features/call/data/call_repository.dart';
import 'package:agorawebrtc/src/features/call/models/call_event.dart';
import 'package:agorawebrtc/src/features/call/models/call_type.dart';
import 'package:agorawebrtc/src/features/call/widgets/active_call/call_active_widget.dart';
import 'package:agorawebrtc/src/features/meeting/models/meeting_params.dart';
import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:l/l.dart';
import 'package:permission_handler/permission_handler.dart';

/// {@template call_screen}
/// CallScope widget.
/// {@endtemplate}
class CallScope extends InheritedWidget {
  /// {@macro call_screen}
  const CallScope({super.key, required this.state, required super.child});

  static CallScreenState of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<CallScope>()?.widget;
    assert(widget != null, 'CallConfigInhWidget was not found in element tree');
    return (widget as CallScope).state;
  }

  final CallScreenState state;

  @override
  bool updateShouldNotify(covariant CallScope oldWidget) => false;
}

/// Receives [MeetingParams], initializes the Agora engine, and manages the
/// active call lifecycle. Automatically pops when the call ends.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.params});

  final MeetingParams params;

  @override
  State<CallScreen> createState() => CallScreenState();
}

class CallScreenState extends State<CallScreen> {
  late final ICallRepository _repository;
  late final CallController callController;
  late final CallMediaController callMediaController;
  late final CallMembersController callMembersController;
  late final RtcEngine rtcEngine;
  late final Stream<CallEvent> _callEventStream;

  bool _isInitializing = true;
  bool _initialized = false;

  /// Becomes true once join has been dispatched, so we don't pop on the
  /// initial idle state before the call even starts.
  bool _callHasStarted = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    if (_initialized) {
      callController.removeListener(_onCallStateChanged);
      callMediaController.dispose();
      callMembersController.dispose();
      callController.dispose();
      rtcEngine
        ..unregisterEventHandler(const RtcEngineEventHandler())
        ..release();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    final cameraPermission = await _requestPermissions();
    if (!cameraPermission && mounted) {
      Navigator.pop(context);
      return;
    }

    rtcEngine = createAgoraRtcEngine();

    l.d('DEBUG appId: "${Config.agoraAppId}"');
    await rtcEngine.initialize(const RtcEngineContext(appId: Config.agoraAppId));

    if (!mounted) {
      rtcEngine.release();
      return;
    }

    _repository = CallRepositoryImpl(rtcEngine);
    _callEventStream = _repository.onCallEvents();
    callController = CallController(callRepository: _repository, eventStream: _callEventStream);
    callMembersController = CallMembersController(eventStream: _callEventStream);
    callMediaController = CallMediaController(callRepository: _repository);

    callController
      ..addListener(_onCallStateChanged)
      ..join(
        channelName: widget.params.channelName,
        callType: widget.params.callType,
        uid: widget.params.uid,
        token: widget.params.token,
      );

    _initialized = true;
    if (mounted) setState(() => _isInitializing = false);
  }

  void _onCallStateChanged() {
    final s = callController.state;

    if (s is Call$JoiningState || s is Call$ConnectedState) {
      _callHasStarted = true;
    }

    if (s is Call$IdleState || s is Call$ErrorState) {
      callMembersController.reset();
      callMediaController.reset();
      if (_callHasStarted && mounted) {
        if (s is Call$ErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _requestPermissions() async {
    // permission_handler only supports Android and iOS.
    // Desktop and web platforms handle permissions via OS-level mechanisms (entitlements, manifests, etc.).
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows)
      return true;
    final permissions = <Permission>[Permission.microphone];
    if (widget.params.callType == CallType.video) permissions.add(Permission.camera);
    final result = await permissions.request();
    return result.entries.every((value) => value.value == PermissionStatus.granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: _ConnectingWidget());
    }

    return CallScope(
      state: this,
      child: StateConsumer<CallController, CallState>(
        controller: callController,
        builder: (context, state, _) => switch (state) {
          Call$IdleState() || Call$ErrorState() || Call$JoiningState() => const _ConnectingWidget(),
          Call$ConnectedState() => const CallActiveWidget(),
        },
      ),
    );
  }
}

class _ConnectingWidget extends StatelessWidget {
  const _ConnectingWidget();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.teal),
          SizedBox(height: 16),
          Text('Connecting…', style: TextStyle(color: Colors.white70)),
        ],
      ),
    ),
  );
}
