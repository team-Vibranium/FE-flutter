import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_elevation.dart';

/// 기본 카드 컴포넌트
/// AngyCall-Flutter-Design-Spec.md 기반
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? Theme.of(context).colorScheme.surface,
      elevation: elevation ?? AppElevation.level1,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppRadius.md,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppRadius.md,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}
