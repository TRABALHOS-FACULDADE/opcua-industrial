import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class ConnectionStatusBar extends StatelessWidget {
  final bool plcConnected;
  final bool wsConnected;

  const ConnectionStatusBar({
    super.key,
    required this.plcConnected,
    required this.wsConnected,
  });

  @override
  Widget build(BuildContext context) {
    final isFullyConnected = plcConnected && wsConnected;
    final isPartial = wsConnected && !plcConnected;

    final color = isFullyConnected
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.error;

    final label = isFullyConnected
        ? 'PLC Connected'
        : isPartial
            ? 'Server online — PLC disconnected'
            : wsConnected
                ? 'Reconnecting...'
                : 'Server unreachable';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _PulsingDot(color: color, pulse: isFullyConnected),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          _SignalIcon(connected: isFullyConnected || isPartial),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  final Color color;
  final bool pulse;

  const _PulsingDot({required this.color, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );

    if (!pulse) return dot;

    return dot
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 1, end: 1.4, duration: 900.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1.4, end: 1, duration: 900.ms, curve: Curves.easeInOut);
  }
}

class _SignalIcon extends StatelessWidget {
  final bool connected;
  const _SignalIcon({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Icon(
      connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
      size: 16,
      color: connected ? AppColors.success : AppColors.error,
    );
  }
}
