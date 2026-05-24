import 'dart:io';
import 'package:flutter/foundation.dart';

abstract final class ApiConstants {
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);

  static String get baseUrl {
    if (isProduction) return 'http://3.35.10.251/api/v1';
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (Platform.isIOS) return 'http://localhost:8080/api/v1';
    return 'http://10.0.2.2:8080/api/v1';
  }

  static String get wsUrl {
    if (isProduction) return 'ws://3.35.10.251:8080/ws-raw';
    if (kIsWeb) return 'ws://localhost:8080/ws-raw';
    if (Platform.isIOS) return 'ws://localhost:8080/ws-raw';
    return 'ws://10.0.2.2:8080/ws-raw';
  }
}