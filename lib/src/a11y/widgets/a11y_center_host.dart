import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../config/a11y_configuration.dart';
import '../theme/a11y_theme_extension.dart';
import 'a11y_center_presenter.dart';
import 'a11y_center_sheet.dart';
import 'a11y_fab.dart';
import 'a11y_scope_data.dart';

const Duration _centerDuration = Duration(milliseconds: 220);

class A11yCenterHost extends StatefulWidget {
  const A11yCenterHost({
    super.key,
    required this.presenter,
    required this.configuration,
    required this.child,
  });

  final A11yCenterPresenter presenter;
  final A11yConfiguration configuration;
  final Widget child;

  @override
  State<A11yCenterHost> createState() => _A11yCenterHostState();
}

class _A11yCenterHostState extends State<A11yCenterHost>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _centerDuration,
    value: widget.presenter.isOpen ? 1 : 0,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(_curve);

  final FocusScopeNode _centerFocus = FocusScopeNode(debugLabel: 'A11yCenter');

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.presenter.addListener(_sync);
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = A11yThemeExtension.of(context).reduceMotion;
  }

  @override
  void didUpdateWidget(covariant A11yCenterHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presenter == widget.presenter) return;

    oldWidget.presenter.removeListener(_sync);
    widget.presenter.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.presenter.removeListener(_sync);
    _controller.removeStatusListener(_onStatus);
    _centerFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Os observers são notificados na ordem de registro e o _WidgetsAppState se
  // registra antes: com rota empilhada o voltar do sistema desempilha primeiro.
  // packages/flutter/lib/src/widgets/binding.dart
  @override
  Future<bool> didPopRoute() async {
    if (!widget.presenter.isOpen) return false;

    widget.presenter.close();
    return true;
  }

  void _sync() {
    final duration = _reduceMotion ? Duration.zero : null;

    if (widget.presenter.isOpen) {
      _controller.animateTo(1, duration: duration);
    } else {
      _controller.animateBack(0, duration: duration);
    }

    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status.isAnimating || !mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Desligada, a camada não deixa rastro na árvore. Gatear só o FAB deixaria
    // `openCenter()` abrir uma Central que o serviço se recusa a persistir —
    // uma tela que aceita toques e não guarda nada é pior que nenhuma.
    if (!widget.configuration.enabled) return widget.child;

    final open = widget.presenter.isOpen;
    final showsCenter = open || !_controller.isDismissed;
    final fab = open ? null : _fab(context);

    return Stack(
      children: [
        ExcludeFocus(
          excluding: open,
          child: ExcludeSemantics(excluding: open, child: widget.child),
        ),
        if (fab != null)
          Positioned.fill(
            child: Align(
              alignment: widget.configuration.fabAlignment,
              child: Padding(
                padding: widget.configuration.fabPadding,
                child: fab,
              ),
            ),
          ),
        if (showsCenter) Positioned.fill(child: _center(context)),
      ],
    );
  }

  Widget? _fab(BuildContext context) {
    final configuration = widget.configuration;
    if (!configuration.showFab || !widget.presenter.fabVisible) return null;

    final built =
        configuration.fabBuilder?.call(context, widget.presenter.open) ??
        A11yFab(onPressed: widget.presenter.open, configuration: configuration);

    return Semantics(sortKey: const OrdinalSortKey(1000000), child: built);
  }

  Widget _center(BuildContext context) {
    final configuration = widget.configuration;
    final service = A11yScopeData.maybeOf(context)?.service;
    final content =
        configuration.centerBuilder?.call(context, widget.presenter.close) ??
        (service == null
            ? null
            : A11yCenterSheet(
                service: service,
                onClose: widget.presenter.close,
              ));
    if (content == null) return const SizedBox.shrink();

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: configuration.strings.centerTitle,
      child: FocusScope(
        node: _centerFocus,
        child: Stack(
          children: [
            FadeTransition(
              opacity: _curve,
              child: ModalBarrier(
                dismissible: true,
                onDismiss: widget.presenter.close,
                semanticsLabel: configuration.strings.closeCenterLabel,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(position: _slide, child: content),
            ),
          ],
        ),
      ),
    );
  }
}

class A11yFabVisibility extends StatefulWidget {
  const A11yFabVisibility({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  State<A11yFabVisibility> createState() => _A11yFabVisibilityState();
}

class _A11yFabVisibilityState extends State<A11yFabVisibility> {
  A11yCenterPresenter? _presenter;
  bool _hiding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final presenter = A11yScopeData.maybeOf(context)?.presenter;
    if (presenter != _presenter) {
      _release();
      _presenter = presenter;
    }

    _apply();
  }

  @override
  void didUpdateWidget(covariant A11yFabVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) _apply();
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  void _apply() {
    final shouldHide = !widget.visible;
    if (shouldHide == _hiding) return;

    _hiding = shouldHide;
    _defer(shouldHide ? _presenter?.pushFabHidden : _presenter?.popFabHidden);
  }

  void _release() {
    if (!_hiding) return;

    _hiding = false;
    _defer(_presenter?.popFabHidden);
  }

  // O host é ancestral desta rota: mexer no contador durante o build sujaria um
  // elemento já construído no mesmo frame.
  // packages/flutter/lib/src/widgets/framework.dart
  void _defer(VoidCallback? action) {
    if (action == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
