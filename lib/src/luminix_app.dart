import 'package:flutter/material.dart';
import 'package:luminix_flutter/luminix_flutter.dart';

import 'luminix_service_provider.dart';
import 'http/request.dart';
import 'http/response.dart';

class LuminixApp extends StatefulWidget {
  static LuminixAppData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LuminixAppData>()
          as LuminixAppData;

  final AppConfiguration configuration;
  final List<ServiceProviderConstructor> providers;
  final Widget child;
  final Widget? splash;
  final void Function(Application)? onInit;
  final void Function(Response)? onRequestError;

  LuminixApp({
    super.key,
    this.configuration = const AppConfiguration(),
    this.providers = const [],
    this.onInit,
    this.onRequestError,
    this.splash,
    required this.child,
  });

  @override
  State<LuminixApp> createState() => _LuminixAppState();
}

class _LuminixAppState extends State<LuminixApp> {
  late final Application app;

  bool initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.onRequestError != null) {
      Request.setRequestErrorCallback(widget.onRequestError!);
    }
    app = Application()
      ..withProviders([
        LuminixServiceProvider.new,
        ...widget.providers,
      ])
      ..withConfiguration(widget.configuration);

    app.create().then(
      (_) {
        if (!mounted) return;
        setState(() => initialized = true);
        widget.onInit?.call(app);
      },
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'luminix_flutter',
            context: ErrorDescription('ao inicializar a Application'),
          ),
        );
        if (!mounted) return;
        setState(() => initialized = true);
      },
    );
  }

  @override
  void dispose() {
    Request.clearRequestErrorCallback();
    app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LuminixAppData(
      app: app,
      initialized: initialized,
      child: initialized ? widget.child : (widget.splash ?? widget.child),
    );
  }
}

class LuminixAppData extends InheritedWidget {
  LuminixAppData({
    required this.app,
    required this.initialized,
    required super.child,
  });

  final Application app;
  final bool initialized;

  @override
  bool updateShouldNotify(LuminixAppData oldWidget) {
    return oldWidget.app != app || oldWidget.initialized != initialized;
  }
}
