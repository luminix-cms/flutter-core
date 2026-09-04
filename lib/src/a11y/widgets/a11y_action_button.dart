import 'package:flutter/material.dart';

import '../theme/a11y_theme_extension.dart';
import 'a11y_labeled_button.dart';

enum A11yActionEmphasis { filled, outlined, plain }

class A11yActionButton extends StatelessWidget {
  const A11yActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.emphasis = A11yActionEmphasis.filled,
    this.icon,
    this.expand = true,
    this.hint,
  });

  final String label;
  final VoidCallback? onPressed;
  final A11yActionEmphasis emphasis;
  final IconData? icon;
  final bool expand;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = A11yThemeExtension.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null;

    final (background, foreground, border) = switch (emphasis) {
      A11yActionEmphasis.filled => (
        scheme.primary,
        scheme.onPrimary,
        scheme.primary,
      ),
      A11yActionEmphasis.outlined => (
        scheme.surface,
        scheme.onSurface,
        scheme.outline,
      ),
      A11yActionEmphasis.plain => (
        const Color(0x00000000),
        scheme.primary,
        const Color(0x00000000),
      ),
    };

    final opacity = enabled ? 1.0 : 0.38;

    return A11yLabeledButton(
      label: label,
      hint: hint,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background.withValues(alpha: background.a * opacity),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: border.withValues(alpha: border.a * opacity),
            width: extension.borderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: foreground.withValues(alpha: foreground.a * opacity),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground.withValues(alpha: foreground.a * opacity),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
