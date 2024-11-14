import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:luminix_flutter/src/model.dart';
import 'package:luminix_flutter/src/property_bag.dart';
import 'package:luminix_flutter/src/route.dart';

import 'types/app_configuration.dart';

class AppFacades {
  PropertyBag<AppConfiguration>? config;
  RouteFacade? route;
  ModelFacade? model;

  AppFacades({
    this.config,
    this.route,
    this.model,
  });

  boot(LuminixApp app) {
    model?.boot(app);
  }
}

class LuminixApp extends InheritedWidget {
  final AppFacades facades = AppFacades();

  LuminixApp({
    super.key,
    required super.child,
  });

  boot(AppConfiguration configObject) async {
    final bootUrl = (configObject.url ?? '') +
        (configObject.bootUrl ?? '/luminix-api/init');

    var manifest = <String, dynamic>{};

    try {
      final response = await Dio().request(bootUrl);
      if (response.data != null && response.data is Map) {
        manifest.addAll(response.data);
      }
    } catch (error) {
      if (configObject.debug == true) {
        print(error);
      }
    }

    final {'routes': routes, 'models': models} = manifest;

    facades.config = PropertyBag(bag: AppConfiguration());

    facades.route = RouteFacade(routes, configObject.url ?? '');
    facades.model = ModelFacade(models);

    // Boot facades
    facades.boot(this);
  }

  static LuminixApp of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LuminixApp>()!;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}
