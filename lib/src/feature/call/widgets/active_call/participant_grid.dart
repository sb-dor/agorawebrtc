import 'dart:math' as math;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/empty_slot_tile.dart';
import 'package:flutter_project/src/feature/call/widgets/active_call/participant_tile.dart';

/// Grid showing every participant including the local user (uid 0).
/// Empty slots fill any remainder with [EmptySlotTile].
class ParticipantGrid extends StatelessWidget {
  const ParticipantGrid({
    super.key,
    required this.remoteUids,
    required this.channelName,
    required this.engine,
    required this.isCameraOff,
  });

  final List<int> remoteUids;
  final String channelName;
  final RtcEngine engine;
  final bool isCameraOff;

  @override
  Widget build(BuildContext context) {
    // Local user (uid 0) is always first so the creator is always visible.
    final allUids = [0, ...remoteUids];
    final count = allUids.length;
    final crossAxisCount = count <= 4 ? 2 : 3;
    final rows = (count / crossAxisCount).ceil();
    final capacity = rows * crossAxisCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - (crossAxisCount - 1) * 2) / crossAxisCount;
        final cellH = (constraints.maxHeight - (rows - 1) * 2) / rows;
        final aspectRatio = cellW / math.max(cellH, 1);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: capacity,
          itemBuilder: (context, index) {
            if (index >= count) return const EmptySlotTile();
            final uid = allUids[index];
            final isLocal = uid == 0;
            return ParticipantTile(
              uid: uid,
              channelName: channelName,
              engine: engine,
              isLocal: isLocal,
              cameraOff: isLocal && isCameraOff,
            );
          },
        );
      },
    );
  }
}
