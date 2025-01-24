import 'package:luminix_flutter/src/http/response.dart';

bool isValidationError(Response response) {
  if (response.unprocessableEntity()) {
    if (response.json()
        case {'message': String _, 'errors': Map<String, List<String>> _}) {
      return true;
    }
  }
  return false;
}
