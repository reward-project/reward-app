import '../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'web_storage.dart' if (dart.library.io) 'mobile_storage.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // 모바일용 보안 저장소
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // 웹에서 쿠키 가져오기 (OAuth 리다이렉트용)
  static String? getCookie(String name) {
    return WebStorage.getCookie(name);
  }

  // 토큰 저장
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      WebStorage.setItem(_accessTokenKey, accessToken);
      WebStorage.setItem(_refreshTokenKey, refreshToken);
    } else if (AppConfig.isDesktop) {
      // 데스크톱의 경우 secure storage 대신 shared preferences 사용
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  // 토큰 가져오기
  static Future<String?> getToken() async {
    if (kIsWeb) {
      return WebStorage.getItem(_accessTokenKey);
    } else if (AppConfig.isDesktop) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } else {
      return await _secureStorage.read(key: _accessTokenKey);
    }
  }

  // 리프레시 토큰 가져오기
  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return WebStorage.getItem(_refreshTokenKey);
    } else {
      return await _secureStorage.read(key: _refreshTokenKey);
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    if (kIsWeb) {
      WebStorage.removeItem(_accessTokenKey);
      WebStorage.removeItem(_refreshTokenKey);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    }
  }

  // 인증 상태 확인
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // PKCE 파라미터 저장
  static Future<void> storePKCEParameters(String codeVerifier, String state) async {
    if (kIsWeb) {
      WebStorage.setItem('code_verifier', codeVerifier);
      WebStorage.setItem('oauth_state', state);
    } else if (AppConfig.isDesktop) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('code_verifier', codeVerifier);
      await prefs.setString('oauth_state', state);
    } else {
      await _secureStorage.write(key: 'code_verifier', value: codeVerifier);
      await _secureStorage.write(key: 'oauth_state', value: state);
    }
  }

  // PKCE 파라미터 가져오기
  static Future<Map<String, String?>> getPKCEParameters() async {
    String? codeVerifier;
    String? state;
    
    if (kIsWeb) {
      codeVerifier = WebStorage.getItem('code_verifier');
      state = WebStorage.getItem('oauth_state');
    } else if (AppConfig.isDesktop) {
      final prefs = await SharedPreferences.getInstance();
      codeVerifier = prefs.getString('code_verifier');
      state = prefs.getString('oauth_state');
    } else {
      codeVerifier = await _secureStorage.read(key: 'code_verifier');
      state = await _secureStorage.read(key: 'oauth_state');
    }
    
    return {
      'codeVerifier': codeVerifier,
      'state': state,
    };
  }

  // PKCE 파라미터 삭제
  static Future<void> clearPKCEParameters() async {
    if (kIsWeb) {
      WebStorage.removeItem('code_verifier');
      WebStorage.removeItem('oauth_state');
    } else if (AppConfig.isDesktop) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('code_verifier');
      await prefs.remove('oauth_state');
    } else {
      await _secureStorage.delete(key: 'code_verifier');
      await _secureStorage.delete(key: 'oauth_state');
    }
  }
} 