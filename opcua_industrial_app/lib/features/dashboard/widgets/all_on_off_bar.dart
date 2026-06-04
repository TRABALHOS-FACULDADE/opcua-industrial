import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AllOnOffBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onAllOn;
  final VoidCallback onAllOff;

  const AllOnOffBar({
    super.key,
    required this.enabled,
    required this.onAllOn,
    required this.onAllOff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: enabled ? onAllOn : null,
              icon: const Icon(Icons.flash_on_rounded, size: 16),
              label: const Text('ALL ON'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: enabled
                      ? AppColors.accent.withValues(alpha: 0.6)
                      : AppColors.border,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: enabled ? onAllOff : null,
              icon: const Icon(Icons.flash_off_rounded, size: 16),
              label: const Text('ALL OFF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(
                  color: enabled ? AppColors.border : AppColors.textDisabled,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
