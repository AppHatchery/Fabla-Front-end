import 'package:dio/dio.dart';

import 'breadcrumb_dio_interceptor.dart';

class DioClient {
  DioClient._();

  static final Dio instance = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.add(BreadcrumbDioInterceptor());
}
