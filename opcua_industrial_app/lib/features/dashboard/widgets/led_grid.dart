import 'package:flutter/material.dart';
import '../../../data/models/lamp_state.dart';
import 'led_card.dart';

class LedGrid extends StatelessWidget {
  final List<LampState> lamps;
  final Set<int> pendingIds;
  final bool plcConnected;
  final void Function(int id, bool state) onToggle;

  const LedGrid({
    super.key,
    required this.lamps,
    required this.pendingIds,
    required this.plcConnected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: lamps.length,
        itemBuilder: (context, i) {
          final lamp = lamps[i];
          return LedCard(
            key: ValueKey(lamp.id),
            lamp: lamp,
            isPending: pendingIds.contains(lamp.id),
            plcConnected: plcConnected,
            onToggle: (state) => onToggle(lamp.id, state),
          );
        },
      ),
    );
  }
}
