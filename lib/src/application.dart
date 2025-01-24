import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/utils.dart';

typedef ServiceProviderConstructor = ServiceProvider Function(Application app);

class ServiceLoader {
  final Function loader;
  final bool singleton;

  ServiceLoader(this.loader, {this.singleton = false});
}

class Application {
  Map<String, dynamic> _configuration = {};
  Map<String, dynamic> singletons = {};
  Map<String, ServiceLoader> loaders = {};
  List<ServiceProviderConstructor> providers = [];

  Application([List<ServiceProviderConstructor>? providers]) : super() {
    if (providers != null) {
      this.providers.addAll(providers);
    }
  }

  Map<String, ServiceLoader> get services => loaders;
  Map<String, dynamic> get configuration => _configuration;

  Future<void> loadConfiguration() async {
    // TODO: find ways to improve this
    try {
      final manifestString =
          await rootBundle.loadString('lib/src/models/manifest.json');
      final manifestJson = jsonDecode(manifestString);
      withConfiguration(AppConfiguration(manifest: manifestJson));
    } catch (e) {
      print('An error ocurred while loading the manifest: $e');
    }
  }

  void bind(String abstract, Function concrete) {
    loaders[abstract] = ServiceLoader(concrete);
  }

  void singleton(String abstract, Function concrete) {
    loaders[abstract] = ServiceLoader(concrete, singleton: true);
  }

  dynamic make(String abstract) {
    var loader = loaders[abstract];
    if (loader == null) {
      throw Exception('Service "$abstract" is not bound in the container.');
    }
    if (loader.singleton) {
      if (!singletons.containsKey(abstract)) {
        singletons[abstract] = loader.loader();
      }
      return singletons[abstract];
    }
    return loader.loader();
  }

  void withConfiguration(AppConfiguration configuration) {
    _configuration = mergeMaps(_configuration, configuration.toJson());
  }

  void withProviders(List<ServiceProviderConstructor> providers) {
    this.providers.addAll(providers);
  }

  Future<void> create() async {
    await loadConfiguration();

    var providerInstances = providers.map((providerType) {
      return (providerType as dynamic Function(Application)).call(this)
          as ServiceProvider;
    }).toList();

    // init'

    for (var provider in providerInstances) {
      provider.register();
    }

    // booting

    for (var provider in providerInstances) {
      provider.boot();
    }

    // booted

    // once('flushing', () {
    //   for (var provider in providerInstances) {
    //     provider.flush();
    //   }
    // });

    // ready
  }

  void dispose() {
    // flushing

    singletons.clear();
    loaders.clear();
    _configuration.clear();
    providers.clear();

    // flushed
  }
}
