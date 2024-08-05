import 'package:flutter/widgets.dart';
import 'package:luminix_flutter_core/src/property_bag.dart';

import 'types/app_configuration.dart';

class LuminixApp extends InheritedWidget {
  final PropertyBag<AppConfiguration> configuration;

  LuminixApp({
    super.key,
    required this.configuration,
    required super.child,
  });

  static LuminixApp of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LuminixApp>()!;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}
