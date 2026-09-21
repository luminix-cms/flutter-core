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
  final List<ServiceProvider> _providerInstances = [];

  Application([List<ServiceProviderConstructor>? providers]) : super() {
    if (providers != null) {
      this.providers.addAll(providers);
    }
  }

  Map<String, ServiceLoader> get services => loaders;
  Map<String, dynamic> get configuration => _configuration;

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
    _configuration = mergeMaps(_configuration, configuration.toMap());
  }

  void withProviders(List<ServiceProviderConstructor> providers) {
    this.providers.addAll(providers);
  }

  Future<void> create() async {
    _providerInstances
      ..clear()
      ..addAll(
        providers.map((providerType) {
          return (providerType as dynamic Function(Application)).call(this)
              as ServiceProvider;
        }),
      );

    for (var provider in _providerInstances) {
      provider.register();
    }

    for (var provider in _providerInstances) {
      await provider.boot();
    }
  }

  void dispose() {
    for (var provider in _providerInstances.reversed) {
      provider.flush();
    }

    _providerInstances.clear();
    singletons.clear();
    loaders.clear();
    _configuration.clear();
    providers.clear();
  }
}
