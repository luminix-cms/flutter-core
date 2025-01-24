import 'dart:convert';

import 'package:qs_dart/qs_dart.dart';

import 'request.dart';

typedef ClientContructor = Client Function();

class Client {
  final String? baseUrl;
  final Map<String, String> headers;
  final Map<String, dynamic>? params;
  final Map<String, dynamic>? data;

  Client({
    this.baseUrl,
    this.headers = const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    this.params,
    this.data,
  });

  Client asForm() {
    return copyWith(headers: {
      ...headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    });
  }

  Client accept(String type) {
    return copyWith(headers: {
      ...headers,
      'Accept': type,
    });
  }

  Client acceptJson() {
    return accept('application/json');
  }

  Client withHeaders(Map<String, String> headers) {
    return copyWith(headers: {
      ...this.headers,
      ...headers,
    });
  }

  Client withParams(Map<String, dynamic> params) {
    return copyWith(params: {
      if (this.params is Map) ...this.params!,
      ...params,
    });
  }

  Client withBasicAuth(String username, String password) {
    final auth = base64Encode(utf8.encode('$username:$password'));
    return copyWith(headers: {
      ...headers,
      'Authorization': 'Basic $auth',
    });
  }

  Client withBearerToken(String token) {
    return copyWith(headers: {
      ...headers,
      'Authorization': 'Bearer $token',
    });
  }

  Request<T> get<T>(String url) {
    return Request<T>(
      url: buildUrl(url),
      headers: headers,
    );
  }

  Request<T> post<T>(String url) {
    return Request<T>(
      url: buildUrl(url),
      headers: headers,
      method: 'POST',
    );
  }

  Request<T> put<T>(String url) {
    return Request<T>(
      url: buildUrl(url),
      headers: headers,
      method: 'PUT',
    );
  }

  Request<T> patch<T>(String url) {
    return Request<T>(
      url: buildUrl(url),
      headers: headers,
      method: 'PATCH',
    );
  }

  Request<T> delete<T>(String url) {
    return Request<T>(
      url: buildUrl(url),
      headers: headers,
      method: 'DELETE',
    );
  }

  Request<T> call<T>(String method, String url) {
    return Request<T>(
      url: buildUrl(url),
      headers: headers,
      method: method,
      data: jsonEncode(data),
    );
  }

  Uri buildUrl(String path) {
    if (baseUrl == null) {
      return Uri.parse(path).replace(
        query: QS.encode(
            params, const EncodeOptions(encodeValuesOnly: true, encode: false)),
      );
    }
    return Uri.parse(baseUrl!).replace(path: path, queryParameters: params);
  }

  Client copyWith({
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    Map<String, dynamic>? data,
  }) {
    return Client(
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? this.headers,
      params: params ?? this.params,
      data: data ?? this.data,
    );
  }
}
