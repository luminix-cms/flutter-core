import 'package:flutter/widgets.dart';
import 'package:luminix_flutter_core/luminix_flutter_core.dart';

dynamic config(
  BuildContext context, {
  required String field,
  dynamic defaultValue,
}) {
  return LuminixApp.of(context).configuration.get<dynamic>(field, defaultValue);
}
