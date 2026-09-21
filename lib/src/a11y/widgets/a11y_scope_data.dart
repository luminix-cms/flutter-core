import 'package:flutter/material.dart';

import '../a11y_service.dart';
import '../config/a11y_configuration.dart';
import '../models/a11y_settings.dart';
import '../theme/a11y_theme_adapter.dart';
import 'a11y_center_presenter.dart';

class A11yScopeData extends InheritedWidget {
  const A11yScopeData({
    super.key,
    required this.service,
    required this.settings,
    required this.configuration,
    required this.baseTheme,
    required this.platformTextScaler,
    required this.adapter,
    required this.presenter,
    required this.centerIsOpen,
    required super.child,
  });

  final A11yService? service;
  final A11ySettings settings;
  final A11yConfiguration configuration;

  // O tema do app antes do adapter: a prévia precisa dele para simular ajustes
  // pendentes sem adaptar duas vezes o que já está adaptado.
  final ThemeData baseTheme;

  // A escala do sistema antes de compor com a do usuário: a prévia compõe a
  // sua própria e dobraria o ajuste se partisse da escala já aplicada.
  final TextScaler platformTextScaler;
  final A11yThemeAdapter adapter;
  final A11yCenterPresenter presenter;
  final bool centerIsOpen;

  void openCenter() => presenter.open();

  void closeCenter() => presenter.close();

  static A11yScopeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<A11yScopeData>();

  static A11yScopeData of(BuildContext context) {
    final data = maybeOf(context);
    if (data != null) return data;

    throw FlutterError.fromParts([
      ErrorSummary('A11yScopeData.of foi chamado sem um A11yScope acima.'),
      ErrorHint(
        'Passe builder: A11yScope.builder() ao MaterialApp, ou consulte '
        'A11yScopeData.maybeOf para tolerar a ausência do escopo.',
      ),
    ]);
  }

  @override
  bool updateShouldNotify(A11yScopeData oldWidget) =>
      oldWidget.service != service ||
      oldWidget.settings != settings ||
      oldWidget.configuration != configuration ||
      oldWidget.baseTheme != baseTheme ||
      oldWidget.platformTextScaler != platformTextScaler ||
      oldWidget.adapter != adapter ||
      oldWidget.presenter != presenter ||
      oldWidget.centerIsOpen != centerIsOpen;
}
