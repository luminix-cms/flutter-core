import 'package:flutter/material.dart';

import '../config/a11y_configuration.dart';
import '../models/a11y_settings.dart';
import '../theme/a11y_text_scaler.dart';
import '../theme/a11y_theme_adapter.dart';
import '../theme/a11y_theme_extension.dart';
import 'a11y_grayscale_filter.dart';
import 'a11y_scope_data.dart';

class A11yPreviewCard extends StatelessWidget {
  const A11yPreviewCard({super.key, required this.settings, this.sample});

  final A11ySettings settings;
  final String? sample;

  @override
  Widget build(BuildContext context) {
    final scope = A11yScopeData.maybeOf(context);
    final configuration = scope?.configuration ?? const A11yConfiguration();
    final adapter = scope?.adapter ?? const A11yThemeAdapter();

    // O tema base é o do app, nunca o já adaptado pelo escopo: adaptar duas
    // vezes empilharia contraste sobre contraste e fonte sobre fonte.
    final base = scope?.baseTheme ?? Theme.of(context);
    final data = adapter.attachExtension(
      adapter.adapt(base, settings),
      settings,
    );

    final media = MediaQuery.of(context);
    final textScaler = A11yTextScaler.resolve(
      platform: scope?.platformTextScaler ?? media.textScaler,
      factor: settings.textScale,
      maxScaleFactor: configuration.previewMaxTextScale,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: MediaQuery(
        data: media.copyWith(
          textScaler: textScaler,
          boldText: settings.boldText,
          disableAnimations: settings.reduceMotion,
        ),
        child: Theme(
          data: data,
          child: A11yGrayscaleFilter(
            enabled: settings.contrastMode == A11yContrastMode.grayscale,
            child: Builder(builder: _content),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final extension = A11yThemeExtension.of(context);
    final scheme = theme.colorScheme;
    final strings =
        A11yScopeData.maybeOf(context)?.configuration.strings ??
        const A11yConfiguration().strings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: extension.borderWidth),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.previewSectionLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sample ?? strings.previewSample,
            style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
