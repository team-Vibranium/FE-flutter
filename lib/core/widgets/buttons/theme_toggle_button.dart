import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_radius.dart';

/// 테마 변경 토글 버튼
class ThemeToggleButton extends ConsumerWidget {
  final bool showLabel;
  final double? iconSize;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    if (showLabel) {
      return InkWell(
        onTap: () => themeNotifier.toggleTheme(),
        borderRadius: AppRadius.md,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                themeNotifier.currentThemeIcon,
                size: iconSize ?? 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '테마 설정',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      themeNotifier.currentThemeName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => themeNotifier.toggleTheme(),
      icon: Icon(
        themeNotifier.currentThemeIcon,
        size: iconSize ?? 24,
      ),
      tooltip: '테마 변경: ${themeNotifier.currentThemeName}',
    );
  }
}
