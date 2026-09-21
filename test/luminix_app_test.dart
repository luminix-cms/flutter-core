import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:luminix_flutter/luminix_flutter.dart';

class _ThrowingBootProvider extends ServiceProvider {
  _ThrowingBootProvider(super.application);

  @override
  Future<void> boot() async => throw StateError('boot falhou');
}

Widget _host({
  Widget? splash,
  List<ServiceProviderConstructor> providers = const [],
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: LuminixApp(
      providers: providers,
      splash: splash,
      child: const Text('conteudo'),
    ),
  );
}

void main() {
  tearDown(GetIt.instance.reset);

  testWidgets('duas montagens seguidas não colidem no GetIt', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('conteudo'), findsOneWidget);
  });

  testWidgets('desmontar desregistra os serviços do GetIt', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(GetIt.instance.isRegistered<RouteService>(), isTrue);
    expect(GetIt.instance.isRegistered<PropertyBag>(), isTrue);

    await tester.pumpWidget(const SizedBox());

    expect(GetIt.instance.isRegistered<RouteService>(), isFalse);
    expect(GetIt.instance.isRegistered<PropertyBag>(), isFalse);
  });

  testWidgets('sem splash o filho aparece no primeiro frame', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('conteudo'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('com splash o filho só aparece depois do boot', (tester) async {
    await tester.pumpWidget(_host(splash: const Text('carregando')));

    expect(find.text('carregando'), findsOneWidget);
    expect(find.text('conteudo'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('carregando'), findsNothing);
    expect(find.text('conteudo'), findsOneWidget);
  });

  testWidgets('provider que falha não prende o app no splash', (tester) async {
    await tester.pumpWidget(
      _host(
        splash: const Text('carregando'),
        providers: [_ThrowingBootProvider.new],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isStateError);
    expect(find.text('conteudo'), findsOneWidget);
  });
}
