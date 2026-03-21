import 'dart:math' as math;

import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/src/common/constant/config.dart';
import 'package:flutter_project/src/common/widget/scaffold_padding.dart';
import 'package:flutter_project/src/feature/authentication/widget/authentication_scope.dart';
import 'package:flutter_project/src/feature/call/models/call_type.dart';
import 'package:flutter_project/src/feature/call/widgets/call_screen.dart';
import 'package:flutter_project/src/feature/meeting/controller/meeting_controller.dart';
import 'package:flutter_project/src/feature/meeting/data/token_repository.dart';
import 'package:flutter_project/src/feature/meeting/widgets/controllers/meeting_data_controller.dart';
import 'package:flutter_project/src/feature/meeting/widgets/lobby/meeting_config_warning.dart';
import 'package:flutter_project/src/feature/meeting/widgets/lobby/share_hint.dart';

/// Generates a random Google-Meet-style meeting code, e.g. "abc-defg-hij".
String _generateMeetingCode() {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  final rng = math.Random();
  String part(int len) => List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
  return '${part(3)}-${part(4)}-${part(3)}';
}

/// Lobby screen — create a new meeting or join one with a code.
///
/// [MeetingController] handles token generation. The widget listens via
/// [addListener] and pushes [CallScreen] when params are ready.
class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  late final MeetingController _meetingController;
  final _meetingDataController = MeetingDataController();
  late final TextEditingController _channelController;

  bool _isGenerated = false;

  @override
  void initState() {
    super.initState();
    _meetingController = MeetingController(
      tokenRepository: Config.agoraAppCertificate.isEmpty
          ? const TokenRepositoryNoop()
          : const TokenRepositoryImpl(
              appId: Config.agoraAppId,
              appCertificate: Config.agoraAppCertificate,
            ),
    );
    _channelController = TextEditingController(text: _meetingDataController.lastChannelName);
    _meetingController.addListener(_onMeetingStateChanged);
  }

  void _onMeetingStateChanged() {
    final s = _meetingController.state;
    if (s is Meeting$ReadyState) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => CallScreen(params: s.params)));
    } else if (s is Meeting$ErrorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _meetingController.reset();
    }
  }

  @override
  void dispose() {
    _meetingController
      ..removeListener(_onMeetingStateChanged)
      ..dispose();
    _meetingDataController.dispose();
    _channelController.dispose();
    super.dispose();
  }

  void _newMeeting() {
    _channelController.text = _generateMeetingCode();
    setState(() => _isGenerated = true);
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _channelController.text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting code copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startCall(CallType callType) {
    final channelName = _channelController.text.trim();
    if (channelName.isEmpty) return;
    final user = AuthenticationScope.userOf(context);
    if (user == null) return;

    _meetingDataController.setLastChannelName(channelName);
    _meetingController.prepare(
      channelName: channelName,
      callType: callType,
      uid: user.id,
      tempToken: Config.agoraTempToken.isEmpty ? null : Config.agoraTempToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthenticationScope.userOf(context);
    final theme = Theme.of(context);
    final appIdConfigured = Config.agoraAppId.isNotEmpty;

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
      body: StateConsumer<MeetingController, MeetingState>(
        controller: _meetingController,
        builder: (context, meetingState, _) {
          final isPreparing = meetingState is Meeting$PreparingState;
          final preparingCallType = isPreparing ? meetingState.callType : null;

          return CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: ScaffoldPadding.of(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.video_call_rounded, size: 64, color: Colors.teal),
                      const SizedBox(height: 12),
                      Text(
                        'Agora Call',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── New meeting button ──────────────────────────────────
                      FilledButton.icon(
                        onPressed: (appIdConfigured && !isPreparing) ? _newMeeting : null,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('New Meeting'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or join with a code',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Channel / meeting code field ────────────────────────
                      TextField(
                        controller: _channelController,
                        textInputAction: TextInputAction.done,
                        enabled: !isPreparing,
                        onChanged: (_) {
                          if (_isGenerated) setState(() => _isGenerated = false);
                        },
                        decoration: InputDecoration(
                          labelText: 'Meeting Code',
                          hintText: 'e.g. abc-defg-hij',
                          prefixIcon: const Icon(Icons.meeting_room_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: _isGenerated
                              ? IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.teal),
                                  tooltip: 'Copy code',
                                  onPressed: _copyCode,
                                )
                              : null,
                        ),
                      ),

                      // ── Generated-code share hint ───────────────────────────
                      if (_isGenerated) ...[
                        const SizedBox(height: 10),
                        ShareHint(onCopy: _copyCode),
                      ],

                      const SizedBox(height: 24),

                      // ── Call type buttons ────────────────────────────────────
                      AnimatedBuilder(
                        animation: _channelController,
                        builder: (context, _) {
                          final hasChannel =
                              appIdConfigured && _channelController.text.trim().isNotEmpty;
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: (hasChannel && !isPreparing)
                                      ? () => _startCall(CallType.audio)
                                      : null,
                                  icon: preparingCallType == CallType.audio
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.teal,
                                          ),
                                        )
                                      : const Icon(Icons.call),
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
                                  onPressed: (hasChannel && !isPreparing)
                                      ? () => _startCall(CallType.video)
                                      : null,
                                  icon: preparingCallType == CallType.video
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.videocam),
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

                      if (!appIdConfigured) ...[
                        const SizedBox(height: 24),
                        const MeetingConfigWarning(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
