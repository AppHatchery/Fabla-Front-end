import 'package:dio/dio.dart';

import 'breadcrumbs.dart';

class BreadcrumbDioInterceptor extends Interceptor {
  static const String _startKey = 'breadcrumb_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Breadcrumbs.instance.network('response', data: {
      'method': response.requestOptions.method,
      'path': response.requestOptions.uri.path,
      'status': response.statusCode,
      'durationMs': _durationMs(response.requestOptions),
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Breadcrumbs.instance.network('error', data: {
      'method': err.requestOptions.method,
      'path': err.requestOptions.uri.path,
      'status': err.response?.statusCode,
      'type': err.type.name,
      'durationMs': _durationMs(err.requestOptions),
    });
    handler.next(err);
  }

  int? _durationMs(RequestOptions options) {
    final start = options.extra[_startKey];
    if (start is DateTime) {
      return DateTime.now().difference(start).inMilliseconds;
    }
    return null;
  }
}
