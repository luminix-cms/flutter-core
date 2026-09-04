import 'package:flutter/material.dart';

import '../config/a11y_configuration.dart';
import '../models/a11y_settings.dart';
import '../theme/a11y_theme_extension.dart';
import 'a11y_labeled_button.dart';

class A11yContrastSwatchRow extends StatelessWidget {
  const A11yContrastSwatchRow({
    super.key,
    required this.configuration,
    required this.value,
    required this.onChanged,
    this.modes = A11yContrastMode.values,
  });

  final A11yConfiguration configuration;
  final A11yContrastMode value;
  final ValueChanged<A11yContrastMode> onChanged;
  final List<A11yContrastMode> modes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final mode in modes) _swatch(context, mode)],
    );
  }

  Widget _swatch(BuildContext context, A11yContrastMode mode) {
    final theme = Theme.of(context);
    final extension = A11yThemeExtension.of(context);
    final scheme = theme.colorScheme;
    final label = configuration.strings.contrastLabel(mode);
    final selected = mode == value;

    final (background, foreground) = switch (mode) {
      A11yContrastMode.standard => (scheme.surface, scheme.onSurface),
      A11yContrastMode.grayscale => (
        const Color(0xFF767676),
        const Color(0xFFFFFFFF),
      ),
      A11yContrastMode.enhancedContrast => (scheme.primary, scheme.onPrimary),
      A11yContrastMode.highContrast => (
        const Color(0xFF000000),
        const Color(0xFFFFFFFF),
      ),
    };

    return A11yLabeledButton(
      label: label,
      selected: selected,
      onPressed: () => onChanged(mode),
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                  width: selected
                      ? extension.borderWidth + 1
                      : extension.borderWidth,
                ),
              ),
              child: Icon(
                selected
                    ? configuration.icons.selected
                    : configuration.icons.forContrast(mode),
                size: 20,
                color: foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
