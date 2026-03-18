import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/src/common/constant/config.dart';
import 'package:flutter_project/src/feature/authentication/widget/authentication_scope.dart';
import 'package:flutter_project/src/feature/call/controller/call_controller.dart';
import 'package:flutter_project/src/feature/call/models/call_type.dart';
import 'package:flutter_project/src/feature/call/widgets/call_config_widget.dart';

/// Lobby where the user enters a channel name and chooses the call type.
class CallLobbyWidget extends StatefulWidget {
  const CallLobbyWidget({super.key});

  @override
  State<CallLobbyWidget> createState() => _CallLobbyWidgetState();
}

class _CallLobbyWidgetState extends State<CallLobbyWidget> {
  late final _scope = CallConfigInhWidget.of(context);
  late final _callController = _scope.callController;
  late final _callDataController = _scope.callDataController;
  late final TextEditingController _channelController;

  @override
  void initState() {
    super.initState();
    _channelController = TextEditingController(text: _callDataController.lastChannelName);
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  void _startCall(CallType callType) {
    final channelName = _channelController.text.trim();
    if (channelName.isEmpty) return;
    final user = AuthenticationScope.userOf(context);
    if (user == null) return;
    _callDataController.setLastChannelName(channelName);
    _callController.join(
      channelName: channelName,
      callType: callType,
      uid: user.id,
      token: Config.agoraTempToken.isEmpty ? null : Config.agoraTempToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthenticationScope.userOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.name ?? 'Guest'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => AuthenticationScope.controllerOf(context).logout(),
          ),
        ],
      ),
      body: StateConsumer<CallController, CallState>(
        controller: _callController,
        builder: (context, state, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.video_call_rounded, size: 72, color: Colors.teal),
                  const SizedBox(height: 16),
                  Text(
                    'Start a Call',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a channel name to join or create a call room.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
                  ),
                  if (state is Call$ErrorState) ...[
                    const SizedBox(height: 16),
                    _ErrorCard(message: state.message, onRetry: _callController.retryInit),
                  ],
                  const SizedBox(height: 32),
                  TextField(
                    controller: _channelController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Channel Name',
                      hintText: 'e.g. my-meeting-room',
                      prefixIcon: Icon(Icons.meeting_room_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _channelController,
                    builder: (context, _) {
                      final hasChannel = _channelController.text.trim().isNotEmpty;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: hasChannel ? () => _startCall(CallType.audio) : null,
                              icon: const Icon(Icons.call),
                              label: const Text('Audio'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.teal),
                                foregroundColor: Colors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: hasChannel ? () => _startCall(CallType.video) : null,
                              icon: const Icon(Icons.videocam),
                              label: const Text('Video'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (Config.agoraAppId.isEmpty) ...[
                    const SizedBox(height: 24),
                    const _ConfigWarning(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.red.shade900.withValues(alpha: 0.4),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.redAccent)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning();

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.orange.shade900.withValues(alpha: 0.4),
    child: const Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Agora App ID not configured. '
              'Set AGORA_APP_ID in your config file.',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    ),
  );
}
