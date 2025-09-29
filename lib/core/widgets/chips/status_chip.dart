import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_radius.dart';

/// 상태 표시를 위한 Chip 컴포넌트
/// AngyCall-Flutter-Design-Spec.md 기반
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool useWhiteBackground;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
    this.useWhiteBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: useWhiteBackground ? Colors.white : color.withValues(alpha: 0.1),
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: useWhiteBackground ? color : color.withValues(alpha: 0.3),
            width: useWhiteBackground ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
