import 'dart:async';
import 'dart:convert';
import 'package:dartx/dartx.dart';
import 'package:http/http.dart' as http;
import 'response.dart';

class Request<T> implements Future<Response> {
  final Future<Response> _future;
  Response? response;

  // Callback for token refresh - inject this from your auth service
  static Future<String> Function()? _tokenRefreshCallback;
  static const int _maxRetries = 1;

  Request({
    required Uri url,
    String method = 'GET',
    Map<String, String>? headers,
    String? data,
    List<http.MultipartFile>? files,
  }) : _future = _makeRequest(url, method, headers, data, files);

  static void setTokenRefreshCallback(Future<String> Function() callback) {
    _tokenRefreshCallback = callback;
  }

  /// Clears the global token refresh callback. Call this on logout.
  static void clearTokenRefreshCallback() {
    _tokenRefreshCallback = null;
  }

  static Future<Response> _makeRequest(
    Uri url,
    String method,
    Map<String, String>? headers,
    String? data,
    List<http.MultipartFile>? files, [
    int retryCount = 0,
  ]) async {
    try {
      final http.Client client = http.Client();
      final request = files != null && files.isNotEmpty
          ? http.MultipartRequest(method, url)
          : http.Request(method, url);

      if (headers is Map) {
        request.headers.addAll(headers!);
      }

      if (data != null && method.toUpperCase() != 'GET') {
        if (files != null && files.isNotEmpty) {
          final multipartRequest = request as http.MultipartRequest;
          multipartRequest.fields.addAll(
            Map<String, String>.from(
              data.isNotEmpty
                  ? Map<String, dynamic>.from(
                      jsonDecode(data),
                    ).mapValues((entry) => entry.value.toString())
                  : {},
            ),
          );
          for (final file in files) {
            multipartRequest.files.add(file);
          }
        } else {
          (request as http.Request).body = data;
        }
      }

      final streamedResponse = await client.send(request);
      final httpResponse = await http.Response.fromStream(streamedResponse);

      // Check if token expired (401 Unauthorized)
      if (httpResponse.statusCode == 401 && retryCount < _maxRetries) {
        if (_tokenRefreshCallback != null) {
          try {
            // Expect callback to return a new token string (e.g. access token)
            final String newToken = await _tokenRefreshCallback!();

            // Build updated headers and ensure Authorization uses the refreshed token.
            final Map<String, String> updatedHeaders = headers != null
                ? Map<String, String>.from(headers)
                : <String, String>{};

            // Remove any existing Authorization keys (case-sensitive map), then set normalized key.
            updatedHeaders.remove('authorization');
            updatedHeaders.remove('Authorization');
            if (newToken.isNotEmpty) {
              updatedHeaders['Authorization'] = 'Bearer $newToken';
            }

            // Retry the request with refreshed token in headers
            return _makeRequest(
              url,
              method,
              updatedHeaders,
              data,
              files,
              retryCount + 1,
            );
          } catch (e) {
            print('Token refresh failed: $e');
            rethrow;
          }
        }
      }

      final response = Response(httpResponse);
      return response;
    } catch (error) {
      print('request try catch');
      rethrow;
    }
  }

  @override
  Stream<Response> asStream() => _future.asStream();

  @override
  Future<Response> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Response value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<Response> timeout(
    Duration timeLimit, {
    FutureOr<Response> Function()? onTimeout,
  }) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<Response> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }
}
