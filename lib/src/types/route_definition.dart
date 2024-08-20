class RouteDefinition {
  final String name;
  final List<String> methods;

  RouteDefinition({required this.name, required this.methods});

  factory RouteDefinition.fromList(List<String> json) {
    return RouteDefinition(
      name: json.first,
      methods: json.skip(1).toList(),
    );
  }
}
