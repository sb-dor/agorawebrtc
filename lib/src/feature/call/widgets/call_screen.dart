import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/src/common/constant/config.dart';
import 'package:flutter_project/src/feature/call/controller/call_controller.dart';
import 'package:flutter_project/src/feature/call/controller/call_media_controller.dart';
import 'package:flutter_project/src/feature/call/controller/call_members_controller.dart';
import 'package:flutter_project/src/feature/call/data/call_repository.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/call_active_widget.dart';
import 'package:flutter_project/src/feature/meeting/models/meeting_params.dart';

/// Inherited widget that exposes [CallScreenState] to the active-call subtree.
class CallConfigInhWidget extends InheritedWidget {
  const CallConfigInhWidget({super.key, required this.state, required super.child});

  static CallScreenState of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<CallConfigInhWidget>()?.widget;
    assert(widget != null, 'CallConfigInhWidget was not found in element tree');
    return (widget as CallConfigInhWidget).state;
  }

  final CallScreenState state;

  @override
  bool updateShouldNotify(CallConfigInhWidget old) => false;
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

  Future<void> _initialize() async {
    rtcEngine = createAgoraRtcEngine();
    await rtcEngine.initialize(const RtcEngineContext(appId: Config.agoraAppId));

    if (!mounted) {
      rtcEngine.release();
      return;
    }

    _repository = CallRepositoryImpl(rtcEngine);
    callController = CallController(callRepository: _repository);
    callMediaController = CallMediaController(callRepository: _repository);
    callMembersController = CallMembersController(callRepository: _repository);

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
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      callController
        ..removeListener(_onCallStateChanged)
        ..dispose();
      callMediaController.dispose();
      callMembersController.dispose();
      rtcEngine
        ..unregisterEventHandler(const RtcEngineEventHandler())
        ..release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return CallConfigInhWidget(
      state: this,
      child: StateConsumer<CallController, CallState>(
        controller: callController,
        builder: (context, state, _) => switch (state) {
          Call$IdleState() || Call$ErrorState() => const _ConnectingWidget(),
          Call$JoiningState() => const _ConnectingWidget(),
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
