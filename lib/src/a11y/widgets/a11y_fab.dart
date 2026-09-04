import 'package:flutter/material.dart';

import '../config/a11y_configuration.dart';
import '../theme/a11y_theme_extension.dart';
import 'a11y_labeled_button.dart';

const double _fabSize = 56;

class A11yFab extends StatelessWidget {
  const A11yFab({
    super.key,
    required this.onPressed,
    this.configuration = const A11yConfiguration(),
  });

  final VoidCallback onPressed;
  final A11yConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = A11yThemeExtension.of(context);
    final scheme = theme.colorScheme;

    return A11yLabeledButton(
      label: configuration.strings.openCenterLabel,
      onPressed: onPressed,
      minTapTarget: _fabSize,
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(_fabSize / 2),
      // Nada de Tooltip: o host é irmão do Navigator e o long-press iria
      // procurar um Overlay que não existe acima dele.
      // packages/flutter/lib/src/material/tooltip.dart
      child: Container(
        width: _fabSize,
        height: _fabSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primaryContainer,
          border: Border.all(
            color: scheme.onPrimaryContainer,
            width: extension.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.24),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          configuration.icons.center,
          size: 28,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
