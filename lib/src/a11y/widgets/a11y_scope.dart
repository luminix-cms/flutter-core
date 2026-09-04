import 'package:flutter/material.dart';

import '../../luminix_app.dart';
import '../a11y_service.dart';
import '../config/a11y_configuration.dart';
import '../models/a11y_settings.dart';
import '../theme/a11y_text_scaler.dart';
import '../theme/a11y_theme_adapter.dart';
import 'a11y_center_host.dart';
import 'a11y_center_presenter.dart';
import 'a11y_grayscale_filter.dart';
import 'a11y_scope_data.dart';

// Sem serviço o escopo não pode encolher a escala que a pessoa já escolheu no
// sistema: maxTextScale só vale para quem optou pela acessibilidade.
const A11yConfiguration _inert = A11yConfiguration(
  enabled: false,
  showFab: false,
  maxTextScale: double.infinity,
);

class A11yScope extends StatefulWidget {
  const A11yScope({
    super.key,
    required this.child,
    this.service,
    this.adapter = const A11yThemeAdapter(),
  });

  final Widget child;
  final A11yService? service;
  final A11yThemeAdapter adapter;

  static TransitionBuilder builder({
    TransitionBuilder? next,
    A11yThemeAdapter adapter = const A11yThemeAdapter(),
    A11yService? service,
  }) {
    return (BuildContext context, Widget? child) {
      return A11yScope(
        service: service,
        adapter: adapter,
        // O next roda dentro do escopo para enxergar o tema já adaptado.
        child: next == null
            ? (child ?? const SizedBox.shrink())
            : Builder(builder: (context) => next(context, child)),
      );
    };
  }

  @override
  State<A11yScope> createState() => _A11yScopeState();
}

class _A11yScopeState extends State<A11yScope> {
  final A11yCenterPresenter _presenter = A11yCenterPresenter();

  A11yService? _resolved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolved = widget.service ?? _fromContainer(context);
  }

  @override
  void didUpdateWidget(covariant A11yScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _resolved = widget.service ?? _fromContainer(context);
    }
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  // A acessibilidade nunca impede o app de renderizar: sem container, sem
  // serviço registrado ou com o boot ainda em curso, o escopo é transparente.
  A11yService? _fromContainer(BuildContext context) {
    final data = context.dependOnInheritedWidgetOfExactType<LuminixAppData>();
    if (data == null || !data.initialized) return null;

    final service = data.app.make('a11y');
    return service is A11yService ? service : null;
  }

  @override
  Widget build(BuildContext context) {
    final service = _resolved;
    if (service == null) return _mount(context, _inert, A11ySettings.defaults);

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => _mount(
        context,
        service.configuration,
        service.isLoaded ? service.settings : A11ySettings.defaults,
      ),
    );
  }

  // O adapter recebido no construtor vence: quem o passou à mão foi mais
  // específico do que quem preencheu a configuração.
  A11yThemeAdapter _adapterFor(A11yConfiguration configuration) {
    final fonts =
        widget.adapter.fontFamilyOverrides.isEmpty &&
            configuration.fontFamilyOverrides.isNotEmpty
        ? configuration.fontFamilyOverrides
        : null;
    final rebuilder = widget.adapter.themeRebuilder == null
        ? configuration.themeRebuilder
        : null;

    if (fonts == null && rebuilder == null) return widget.adapter;

    return widget.adapter.copyWith(
      fontFamilyOverrides: fonts,
      themeRebuilder: rebuilder,
    );
  }

  Widget _mount(
    BuildContext context,
    A11yConfiguration configuration,
    A11ySettings settings,
  ) {
    final media = MediaQuery.of(context);
    final adapter = _adapterFor(configuration);

    final textScaler = A11yTextScaler.resolve(
      platform: media.textScaler,
      factor: settings.textScale,
      maxScaleFactor: configuration.maxTextScale,
    );
    final boldText = media.boldText || settings.boldText;
    final disableAnimations = media.disableAnimations || settings.reduceMotion;

    final tree = _themed(configuration, settings, adapter, media.textScaler);

    if (textScaler == media.textScaler &&
        boldText == media.boldText &&
        disableAnimations == media.disableAnimations) {
      return tree;
    }

    return MediaQuery(
      data: media.copyWith(
        textScaler: textScaler,
        boldText: boldText,
        disableAnimations: disableAnimations,
      ),
      child: tree,
    );
  }

  Widget _themed(
    A11yConfiguration configuration,
    A11ySettings settings,
    A11yThemeAdapter adapter,
    TextScaler platformTextScaler,
  ) {
    return Builder(
      builder: (context) {
        final base = Theme.of(context);

        return Theme(
          data: adapter.attachExtension(
            adapter.adapt(base, settings),
            settings,
          ),
          child: A11yGrayscaleFilter(
            enabled: settings.contrastMode == A11yContrastMode.grayscale,
            child: ListenableBuilder(
              listenable: _presenter,
              builder: (context, _) => A11yScopeData(
                service: _resolved,
                settings: settings,
                configuration: configuration,
                baseTheme: base,
                platformTextScaler: platformTextScaler,
                adapter: adapter,
                presenter: _presenter,
                centerIsOpen: _presenter.isOpen,
                child: A11yCenterHost(
                  presenter: _presenter,
                  configuration: configuration,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
