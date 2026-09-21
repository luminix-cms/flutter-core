import 'dart:convert';

import 'package:http/http.dart' as http;

class Response {
  final http.Response _response;
  final dynamic _error;

  Response(this._response, [this._error]);

  dynamic error() {
    return _error;
  }

  String body() {
    return _response.body;
  }

  dynamic json() {
    return jsonDecode(_response.body);
  }

  int status() {
    return _response.statusCode;
  }

  bool successful() {
    return status() >= 200 && status() < 300;
  }

  bool redirect() {
    return status() >= 300 && status() < 400;
  }

  bool clientError() {
    return status() >= 400 && status() < 500;
  }

  bool serverError() {
    return status() >= 500;
  }

  bool failed() {
    return clientError() || serverError();
  }

  String header(String name) {
    if (_response.headers[name] == null) {
      throw Exception('Header $name not found');
    }

    return _response.headers[name]!;
  }

  Map<String, String> headers() {
    return _response.headers;
  }

  bool ok() {
    return _response.statusCode == 200;
  }

  bool created() {
    return status() == 201;
  }

  bool accepted() {
    return status() == 202;
  }

  bool noContent() {
    return status() == 204;
  }

  bool movedPermanently() {
    return status() == 301;
  }

  bool found() {
    return status() == 302;
  }

  bool badRequest() {
    return status() == 400;
  }

  bool unauthorized() {
    return status() == 401;
  }

  bool paymentRequired() {
    return status() == 402;
  }

  bool forbidden() {
    return status() == 403;
  }

  bool notFound() {
    return status() == 404;
  }

  bool requestTimeout() {
    return status() == 408;
  }

  bool conflict() {
    return status() == 409;
  }

  bool unprocessableEntity() {
    return status() == 422;
  }

  bool tooManyRequests() {
    return status() == 429;
  }

  Response throwIfFailed() {
    if (failed()) {
      throw _error ?? Exception(body());
    }

    return this;
  }

  Response throwIf(bool Function(Response response) test) {
    return test(this) ? throwIfFailed() : this;
  }

  Response throwIfNot(bool Function(Response response) test) {
    return !test(this) ? throwIfFailed() : this;
  }

  Response throwIfStatus(int status) {
    return this.status() == status ? throwIfFailed() : this;
  }

  Response throwIfNotStatus(int status) {
    return this.status() != status ? throwIfFailed() : this;
  }

  Response throwIfClientError() {
    return clientError() ? throwIfFailed() : this;
  }
}
