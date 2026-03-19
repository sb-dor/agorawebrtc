import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/src/common/constant/config.dart';
import 'package:flutter_project/src/feature/call/controller/call_controller.dart';
import 'package:flutter_project/src/feature/call/data/call_repository.dart';
import 'package:flutter_project/src/feature/call/data/token_repository.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/call_active_widget.dart';
import 'package:flutter_project/src/feature/call/widgets/controllers/call_data_controller.dart';
import 'package:flutter_project/src/feature/call/widgets/lobby/call_lobby_widget.dart';

/// Inherited widget that exposes [CallConfigWidgetState] to the subtree.
class CallConfigInhWidget extends InheritedWidget {
  const CallConfigInhWidget({super.key, required this.state, required super.child});

  static CallConfigWidgetState of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<CallConfigInhWidget>()?.widget;
    assert(widget != null, 'CallConfigInhWidget was not found in element tree');
    return (widget as CallConfigInhWidget).state;
  }

  final CallConfigWidgetState state;

  @override
  bool updateShouldNotify(CallConfigInhWidget old) => false;
}

/// Owns the [CallController] and [CallDataController] lifecycles and renders
/// either the lobby or the active call based on controller state.
class CallConfigWidget extends StatefulWidget {
  const CallConfigWidget({super.key});

  @override
  State<CallConfigWidget> createState() => CallConfigWidgetState();
}

class CallConfigWidgetState extends State<CallConfigWidget> {
  late final CallController callController;
  late final CallDataController callDataController;

  @override
  void initState() {
    super.initState();
    callController = CallController(
      callRepository: CallRepositoryImpl(),
      appId: Config.agoraAppId,
      tokenRepository: Config.agoraAppCertificate.isEmpty
          ? const TokenRepositoryNoop()
          : TokenRepositoryImpl(
              appId: Config.agoraAppId,
              appCertificate: Config.agoraAppCertificate,
            ),
    );
    callDataController = CallDataController();
    callController.initialize();
  }

  @override
  void dispose() {
    callController.dispose();
    callDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallConfigInhWidget(
    state: this,
    child: StateConsumer<CallController, CallState>(
      controller: callController,
      builder: (context, state, _) => switch (state) {
        Call$IdleState() || Call$ErrorState() => const CallLobbyWidget(),
        Call$JoiningState() => const _JoiningWidget(),
        Call$ConnectedState() => const CallActiveWidget(),
      },
    ),
  );
}

class _JoiningWidget extends StatelessWidget {
  const _JoiningWidget();

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
