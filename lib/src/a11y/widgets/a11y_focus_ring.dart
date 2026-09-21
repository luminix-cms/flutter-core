import 'package:flutter/widgets.dart';

import '../theme/a11y_theme_extension.dart';

class A11yFocusRing extends StatefulWidget {
  const A11yFocusRing({
    super.key,
    required this.child,
    this.onActivate,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.onFocusChange,
    this.borderRadius,
    this.mouseCursor = MouseCursor.defer,
  });

  final Widget child;
  final VoidCallback? onActivate;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<bool>? onFocusChange;
  final BorderRadiusGeometry? borderRadius;
  final MouseCursor mouseCursor;

  @override
  State<A11yFocusRing> createState() => _A11yFocusRingState();
}

class _A11yFocusRingState extends State<A11yFocusRing> {
  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: _A11yActivateAction(this),
  };

  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    final theme = A11yThemeExtension.of(context);

    return FocusableActionDetector(
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: widget.mouseCursor,
      actions: _actions,
      onFocusChange: widget.onFocusChange,
      // onShowFocusHighlight já distingue foco de teclado de foco por toque.
      // packages/flutter/lib/src/widgets/focus_manager.dart
      onShowFocusHighlight: _showHighlight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_highlighted && widget.enabled)
            Positioned.fill(child: IgnorePointer(child: _ring(theme))),
        ],
      ),
    );
  }

  void _showHighlight(bool value) {
    if (value == _highlighted) return;
    setState(() => _highlighted = value);
  }

  Widget _ring(A11yThemeExtension theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: theme.focusRingColor,
          width: theme.focusRingWidth,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: theme.focusHaloWidth <= 0
            ? null
            : [
                BoxShadow(
                  color: theme.focusHaloColor,
                  spreadRadius: theme.focusRingWidth + theme.focusHaloWidth,
                ),
              ],
      ),
    );
  }
}

class _A11yActivateAction extends Action<ActivateIntent> {
  _A11yActivateAction(this._ring);

  final _A11yFocusRingState _ring;

  @override
  bool get isActionEnabled =>
      _ring.widget.enabled && _ring.widget.onActivate != null;

  @override
  Object? invoke(ActivateIntent intent) {
    _ring.widget.onActivate?.call();
    return null;
  }
}
