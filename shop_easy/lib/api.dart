import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'https://dummyjson.com',
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
    headers: {'Content-Type': 'application/json'},
  ),
);

String? userAccessToken;
String? userRefreshToken;

Future<void> loadAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  userAccessToken = prefs.getString('auth_token');
  userRefreshToken = prefs.getString('refresh_token');

  if (userAccessToken != null && userAccessToken!.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $userAccessToken';
  } else {
    dio.options.headers.remove('Authorization');
  }
}

Future<void> saveAuthToken(String? token, {String? refreshToken}) async {
  final prefs = await SharedPreferences.getInstance();
  userAccessToken = token;

  if (token != null && token.isNotEmpty) {
    await prefs.setString('auth_token', token);
    dio.options.headers['Authorization'] = 'Bearer $token';

    if (refreshToken != null && refreshToken.isNotEmpty) {
      userRefreshToken = refreshToken;
      await prefs.setString('refresh_token', refreshToken);
    }
  } else {
    userRefreshToken = null;
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    dio.options.headers.remove('Authorization');
  }
}
