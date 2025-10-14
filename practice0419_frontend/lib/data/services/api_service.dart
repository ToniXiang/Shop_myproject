import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:practice0419_frontend/core/constants/app_constants.dart';

import 'auth_service.dart';

class ApiService {
  /// 帶有自動身份驗證的 GET 請求
  static Future<dynamic> authenticatedGetRequest(String endpoint) async {
    return await AuthService.authenticatedRequest('GET', endpoint);
  }

  /// 帶有自動身份驗證的 POST 請求
  static Future<Map<String, dynamic>> authenticatedPostRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return await AuthService.authenticatedRequest('POST', endpoint, body: body);
  }

  /// Sends a GET request to the specified endpoint.
  static Future<dynamic> getRequest(String endpoint, {String? token}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (responseData is Map<String, dynamic>) {
        return responseData;
      } else if (responseData is List) {
        return responseData;
      } else {
        throw Exception('API 回傳格式非 Map 或 List');
      }
    } else {
      throw Exception('${responseData['message']}');
    }
  }

  /// Sends a POST request to the specified endpoint with the given body.
  static Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception('${responseData['message']}');
    }
  }
}
