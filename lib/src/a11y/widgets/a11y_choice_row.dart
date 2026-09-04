import 'package:flutter/material.dart';

import '../theme/a11y_text_scaler.dart';
import '../theme/a11y_theme_extension.dart';
import 'a11y_labeled_button.dart';

class A11yChoice<T> {
  const A11yChoice({
    required this.value,
    required this.label,
    this.hint,
    this.icon,
  });

  final T value;
  final String label;
  final String? hint;
  final IconData? icon;
}

class A11yChoiceRow<T> extends StatelessWidget {
  const A11yChoiceRow({
    super.key,
    required this.choices,
    required this.value,
    required this.onChanged,
    this.textScaleOfLabel,
  });

  final List<A11yChoice<T>> choices;
  final T value;
  final ValueChanged<T> onChanged;

  // As opções de tamanho de texto mostram o próprio efeito no rótulo; as demais
  // deixam nulo e herdam a escala da folha.
  final double Function(int index)? textScaleOfLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < choices.length; i++) _tile(context, choices[i], i),
      ],
    );
  }

  Widget _tile(BuildContext context, A11yChoice<T> choice, int index) {
    final theme = Theme.of(context);
    final extension = A11yThemeExtension.of(context);
    final scheme = theme.colorScheme;
    final selected = choice.value == value;

    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    final scale = textScaleOfLabel?.call(index);

    return A11yLabeledButton(
      label: choice.label,
      hint: choice.hint,
      selected: selected,
      onPressed: () => onChanged(choice.value),
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: extension.borderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (choice.icon != null) ...[
                Icon(choice.icon, size: 20, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                choice.label,
                // Compor com a escala ambiente, nunca substituí-la: um
                // TextScaler.linear aqui encolheria o rótulo abaixo do resto
                // da folha para quem já ampliou a fonte no sistema.
                textScaler: scale == null
                    ? null
                    : A11yTextScaler(
                        inner: MediaQuery.of(context).textScaler,
                        factor: scale,
                      ),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 18, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
