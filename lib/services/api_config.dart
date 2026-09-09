import 'dart:io' show Platform;

class ApiConfig {
  static const int port = 8000;

  static String get host {
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }
    if (Platform.isIOS) {
      return 'localhost';
    }
    return 'localhost';
  }

  static String get baseUrl => 'http://$host:$port/api/v1';

  static Uri uri(String path) => Uri.parse('$baseUrl/$path');
}
