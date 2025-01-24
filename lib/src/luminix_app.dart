import 'package:flutter/material.dart';
import 'package:luminix_flutter/luminix_flutter.dart';

import 'luminix_service_provider.dart';

class LuminixApp extends StatefulWidget {
  static LuminixAppData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LuminixAppData>()
          as LuminixAppData;

  final AppConfiguration configuration;
  final List<ServiceProviderConstructor> providers;
  final Widget child;

  LuminixApp({
    super.key,
    this.configuration = const AppConfiguration(),
    this.providers = const [],
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
    app = Application()
      ..withProviders([LuminixServiceProvider.new, ...widget.providers])
      ..withConfiguration(widget.configuration);

    app.create().then((_) => Future.delayed(Duration(seconds: 3), () {
          setState(() => initialized = true);
        }));
  }

  @override
  void dispose() {
    app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LuminixAppData(
      app: app,
      initialized: initialized,
      child: widget.child,
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
