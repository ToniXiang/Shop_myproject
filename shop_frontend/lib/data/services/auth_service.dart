import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shop_frontend/core/constants/app_constants.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Token 存儲 keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userInfoKey = 'user_info';
  static const String _tokenExpiryKey = 'token_expiry';

  /// 帶有自動 token 刷新的 API 請求
  static Future<Map<String, dynamic>> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    int retryCount = 0,
  }) async {
    const maxRetries = 1;

    String? accessToken = await getAccessToken();

    // 如果沒有 token 或 token 過期，嘗試刷新
    if (accessToken == null || await isTokenExpired()) {
      final refreshSuccess = await refreshToken();
      if (!refreshSuccess) {
        throw Exception('請重新登入');
      }
      accessToken = await getAccessToken();
    }

    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    late http.Response response;

    try {
      if (method.toUpperCase() == 'GET') {
        response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
      } else if (method.toUpperCase() == 'POST') {
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        throw Exception('不支援的 HTTP 方法: $method');
      }

      if (response.statusCode == 401 && retryCount < maxRetries) {
        // Token 可能過期，嘗試刷新後重試
        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          return await authenticatedRequest(
            method,
            endpoint,
            body: body,
            retryCount: retryCount + 1,
          );
        } else {
          throw Exception('身份驗證失敗，請重新登入');
        }
      }

      final responseData = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'API 請求失敗');
      }
    } catch (e) {
      if (retryCount < maxRetries && e.toString().contains('401')) {
        // 網路錯誤導致的 401，嘗試刷新 token 後重試
        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          return await authenticatedRequest(
            method,
            endpoint,
            body: body,
            retryCount: retryCount + 1,
          );
        }
      }
      rethrow;
    }
  }

  /// 清除所有存儲資料（用於開發調試）
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// 獲取 access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// 獲取 refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// 獲取用戶信息
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final userInfoString = await _storage.read(key: _userInfoKey);
    if (userInfoString != null) {
      return jsonDecode(userInfoString) as Map<String, dynamic>;
    }
    return null;
  }

  /// 檢查是否已登入（有有效的 token）
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    // 如果 token 過期，嘗試刷新
    if (await isTokenExpired()) {
      return await refreshToken();
    }

    return true;
  }

  /// 檢查 access token 是否過期
  static Future<bool> isTokenExpired() async {
    final expiryString = await _storage.read(key: _tokenExpiryKey);
    if (expiryString == null) return false;

    final expiryTime = DateTime.parse(expiryString);
    return DateTime.now().isAfter(expiryTime);
  }

  /// 登出，清除所有存儲的身份驗證資料
  static Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userInfoKey);
    await _storage.delete(key: _tokenExpiryKey);
  }

  /// 刷新 access token
  static Future<bool> refreshToken() async {
    try {
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) return false;

      final url = Uri.parse('${ApiConstants.baseUrl}api/token/refresh/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshTokenValue}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newAccessToken = responseData['access'];

        // 保存新的 access token
        await _storage.write(key: _accessTokenKey, value: newAccessToken);

        // 如果返回了新的 refresh token，也要更新
        if (responseData.containsKey('refresh')) {
          await _storage.write(
            key: _refreshTokenKey,
            value: responseData['refresh'],
          );
        }

        // 更新過期時間（假設 access token 有效期為 1 小時）
        final expiryTime = DateTime.now().add(const Duration(hours: 1));
        await _storage.write(
          key: _tokenExpiryKey,
          value: expiryTime.toIso8601String(),
        );

        return true;
      } else {
        // 刷新失敗，清除所有 token
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await logout();
      return false;
    }
  }

  /// 保存登入後的 tokens 和用戶信息
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userInfo,
    int? expiresIn, // access token 有效期（秒）
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _userInfoKey, value: jsonEncode(userInfo));

    if (expiresIn != null) {
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiryTime.toIso8601String(),
      );
    }
  }

  /// 驗證當前 token 是否有效
  static Future<bool> validateToken() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) return false;

      final url = Uri.parse('${ApiConstants.baseUrl}api/token/verify/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': accessToken}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Token 無效，嘗試刷新
        return await refreshToken();
      }
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }
}
