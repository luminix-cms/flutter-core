import 'package:flutter/widgets.dart';

class A11ySemanticsHeader extends StatelessWidget {
  const A11ySemanticsHeader({super.key, required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, label: label, child: child);
}
