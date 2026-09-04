import 'package:flutter/widgets.dart';

import 'a11y_focus_ring.dart';
import 'a11y_tap_target.dart';

class A11yLabeledButton extends StatefulWidget {
  const A11yLabeledButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
    this.hint,
    this.selected,
    this.toggled,
    this.enabled = true,
    this.excludeSemantics = true,
    this.borderRadius,
    this.focusNode,
    this.autofocus = false,
    this.minTapTarget,
    this.margin = const EdgeInsets.all(4),
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final String? hint;
  final bool? selected;
  final bool? toggled;
  final bool enabled;
  final bool excludeSemantics;
  final BorderRadiusGeometry? borderRadius;
  final FocusNode? focusNode;
  final bool autofocus;
  final double? minTapTarget;
  final EdgeInsetsGeometry margin;

  @override
  State<A11yLabeledButton> createState() => _A11yLabeledButtonState();
}

class _A11yLabeledButtonState extends State<A11yLabeledButton> {
  bool _focused = false;

  bool get _active => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _active,
      label: widget.label,
      hint: widget.hint,
      selected: widget.selected,
      toggled: widget.toggled,
      // excludeSemantics descarta o nó do FocusableActionDetector: sem repetir
      // o foco aqui, switch access e navegação por teclado perdem o botão.
      // isFocusable deriva de isFocused, então nulo é o único jeito de dizer
      // "não focável".
      // packages/flutter/lib/src/semantics/semantics.dart
      focused: _active ? _focused : null,
      excludeSemantics: widget.excludeSemantics,
      // excludeSemantics apaga a ação de toque do GestureDetector: sem onTap
      // aqui o leitor de tela anuncia o rótulo e o duplo-toque não ativa nada.
      // packages/flutter/lib/src/semantics/semantics.dart
      onTap: _active ? widget.onPressed : null,
      child: A11yFocusRing(
        enabled: _active,
        onActivate: widget.onPressed,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        borderRadius: widget.borderRadius,
        onFocusChange: _onFocusChange,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _active ? widget.onPressed : null,
          // O GestureDetector fica acima do A11yTapTarget porque dimensiona-se
          // pelo filho: por dentro, a área tocável seria a do conteúdo.
          child: A11yTapTarget(
            minSize: widget.minTapTarget,
            margin: widget.margin,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _onFocusChange(bool value) {
    if (value == _focused) return;
    setState(() => _focused = value);
  }
}
