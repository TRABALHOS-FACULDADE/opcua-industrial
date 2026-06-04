import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/lamp_state.dart';

class LedCard extends StatelessWidget {
  final LampState lamp;
  final bool isPending;
  final bool plcConnected;
  final ValueChanged<bool> onToggle;

  const LedCard({
    super.key,
    required this.lamp,
    required this.isPending,
    required this.plcConnected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = lamp.isOn;
    final canToggle = plcConnected && !isPending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn ? AppColors.accent.withValues(alpha: 0.6) : AppColors.border,
          width: isOn ? 1.5 : 1,
        ),
        boxShadow: isOn
            ? const [
                BoxShadow(
                  color: AppColors.accentGlow,
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canToggle ? () => onToggle(!isOn) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LedIcon(isOn: isOn),
                    const Spacer(),
                    if (isPending)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    else
                      Switch(
                        value: isOn,
                        onChanged: canToggle ? onToggle : null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'LED ${lamp.id}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    isOn ? 'ON' : 'OFF',
                    key: ValueKey(isOn),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isOn ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.06, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }
}

class _LedIcon extends StatelessWidget {
  final bool isOn;
  const _LedIcon({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOn ? AppColors.accentGlow : AppColors.ledOff,
        border: Border.all(
          color: isOn ? AppColors.accent : AppColors.border,
          width: 1.5,
        ),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Icon(
        Icons.lightbulb_rounded,
        size: 18,
        color: isOn ? AppColors.accent : AppColors.textDisabled,
      ),
    );
  }
}
