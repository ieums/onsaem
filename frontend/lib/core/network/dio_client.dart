import 'package:dio/dio.dart';
import 'package:ieum/core/constants/api_constants.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ),
);
