import 'package:flutter/material.dart';

import '../config/a11y_configuration.dart';
import '../models/a11y_profile.dart';
import '../theme/a11y_theme_extension.dart';
import 'a11y_labeled_button.dart';

class A11yProfileCard extends StatelessWidget {
  const A11yProfileCard({
    super.key,
    required this.configuration,
    required this.profile,
    required this.selected,
    required this.onToggle,
    this.showSubtitle = true,
    this.width,
  });

  final A11yConfiguration configuration;
  final A11yProfile profile;
  final bool selected;
  final VoidCallback onToggle;
  final bool showSubtitle;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = A11yThemeExtension.of(context);
    final scheme = theme.colorScheme;
    final strings = configuration.strings;

    final title = strings.profileTitle(profile);
    final subtitle = strings.profileSubtitle(profile);

    final background = selected ? scheme.primaryContainer : scheme.surface;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return A11yLabeledButton(
      label: title,
      hint: subtitle,
      selected: selected,
      onPressed: onToggle,
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.zero,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? extension.borderWidth + 1 : extension.borderWidth,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  configuration.iconFor(profile),
                  size: 24,
                  color: foreground,
                ),
                const Spacer(),
                // A seleção nunca é sinalizada só por cor: o ícone repete o
                // estado pra quem não distingue o preenchimento.
                Icon(
                  selected
                      ? configuration.icons.selected
                      : configuration.icons.unselected,
                  size: 20,
                  color: foreground,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(color: foreground),
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
