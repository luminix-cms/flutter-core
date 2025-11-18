import 'dart:async';
import 'dart:convert';
import 'package:dartx/dartx.dart';
import 'package:http/http.dart' as http;
import 'response.dart';

class Request<T> implements Future<Response> {
  final Future<Response> _future;
  Response? response;

  Request({
    required Uri url,
    String method = 'GET',
    Map<String, String>? headers,
    String? data,
    List<http.MultipartFile>? files,
  }) : _future = _makeRequest(url, method, headers, data, files);

  static Future<Response> _makeRequest(
      Uri url,
      String method,
      Map<String, String>? headers,
      String? data,
      List<http.MultipartFile>? files) async {
    try {
      final http.Client client = http.Client();
      final request = files == null
          ? http.Request(method, url)
          : http.MultipartRequest(method, url);

      if (headers is Map) {
        request.headers.addAll(headers!);
      }

      if (data != null && method.toUpperCase() != 'GET') {
        if (files != null && files.isNotEmpty) {
          final multipartRequest = request as http.MultipartRequest;
          multipartRequest.fields.addAll(Map<String, String>.from(
              data.isNotEmpty
                  ? Map<String, dynamic>.from(jsonDecode(data))
                      .mapValues((entry) => entry.value.toString())
                  : {}));
          for (final file in files) {
            multipartRequest.files.add(file);
          }
        } else {
          (request as http.Request).body = data;
        }
      }

      final streamedResponse = await client.send(request);
      final httpResponse = await http.Response.fromStream(streamedResponse);

      final response = Response(httpResponse);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  @override
  Stream<Response> asStream() => _future.asStream();

  @override
  Future<Response> catchError(Function onError,
      {bool Function(Object error)? test}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(Response value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<Response> timeout(Duration timeLimit,
      {FutureOr<Response> Function()? onTimeout}) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<Response> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }
}
