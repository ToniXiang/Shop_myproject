import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// 應用程式常數設定
const double windowWidth = 400;
const double windowHeight = 800;

// API 設定
class ApiConstants {
  // Android Emulator 需要使用 10.0.2.2 來訪問主機的 localhost
  // iOS Simulator 和其他平台可以使用 127.0.0.1
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/'; // Web 使用 localhost
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/'; // Android Emulator 特殊地址
    } else {
      return 'http://127.0.0.1:8000/'; // iOS/其他平台
    }
  }
}

// 應用程式設定
class AppConfig {
  static const String appTitle = "資工購物平台";
}
