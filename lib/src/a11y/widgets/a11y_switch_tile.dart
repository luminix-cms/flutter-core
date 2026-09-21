import 'package:flutter/material.dart';

import 'a11y_labeled_button.dart';

class A11ySwitchTile extends StatelessWidget {
  const A11ySwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.icon,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return A11yLabeledButton(
      label: label,
      hint: description,
      toggled: value,
      onPressed: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  if (description != null)
                    Text(
                      description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // O Switch é decorativo aqui: o toque e a semântica são do botão de
            // fora, e dois nós tocáveis empilhados confundem o leitor de tela.
            ExcludeSemantics(
              child: IgnorePointer(
                child: Switch(value: value, onChanged: onChanged),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
