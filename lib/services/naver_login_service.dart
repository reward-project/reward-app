import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import '../config/app_config.dart';

class NaverLoginService {
  static final NaverLoginService _instance = NaverLoginService._internal();
  factory NaverLoginService() => _instance;
  NaverLoginService._internal();

  late final Dio _dio;

  void init(Dio dio) {
    _dio = dio;
  }

  // 네이버 SDK 초기화
  static Future<void> initializeNaverSDK() async {
    try {
      await NaverLoginSDK.initialize(
        clientId: '2aGPAheEeSLvfbHOHDIB',  // 네이버 앱 클라이언트 ID
        clientSecret: '2aGPAheEeSLvfbHOHDIB',        // 네이버 앱 클라이언트 시크릿
        clientName: 'Reward App',           // 앱 이름
      );
      if (kDebugMode) {
        print('네이버 로그인 SDK 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('네이버 로그인 SDK 초기화 실패: $e');
      }
    }
  }

  // 네이버 네이티브 로그인
  Future<Map<String, dynamic>?> loginWithNaver() async {
    try {
      if (kDebugMode) {
        print('네이버 네이티브 로그인 시작');
      }
      
      // Completer를 사용하여 콜백을 Future로 변환
      final completer = Completer<Map<String, dynamic>?>();
      
      // 네이버 네이티브 SDK로 로그인
      NaverLoginSDK.authenticate(
        callback: OAuthLoginCallback(
          onSuccess: () async {
            try {
              // 로그인 성공 후 액세스 토큰 가져오기
              final accessToken = await NaverLoginSDK.getAccessToken();
              
              if (accessToken != null && accessToken.isNotEmpty) {
                if (kDebugMode) {
                  print('네이버 로그인 성공 - Access Token 획득');
                }
                
                // 네이버 액세스 토큰으로 서버에서 JWT 토큰 발급
                final response = await _dio.post(
                  '/oauth2/token',
                  data: {
                    'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
                    'subject_token': accessToken,
                    'subject_token_type': 'urn:ietf:params:oauth:token-type:access_token',
                    'provider': 'naver',
                    'scope': 'openid profile email api.read api.write',
                  },
                  options: Options(
                    headers: {
                      'Content-Type': 'application/x-www-form-urlencoded',
                      'Authorization': 'Basic ${AppConfig.getMobileClientCredentials()}',
                    },
                  ),
                );
                
                if (response.statusCode == 200 && response.data != null) {
                  if (kDebugMode) {
                    print('네이버 토큰 교환 성공');
                  }
                  completer.complete(response.data);
                } else {
                  completer.completeError(Exception('토큰 교환 실패'));
                }
              } else {
                completer.completeError(Exception('액세스 토큰을 가져올 수 없습니다'));
              }
            } catch (e) {
              completer.completeError(e);
            }
          },
          onFailure: (httpStatus, message) {
            if (kDebugMode) {
              print('네이버 로그인 실패 - HTTP Status: $httpStatus, Message: $message');
            }
            completer.completeError(Exception('네이버 로그인 실패: $message'));
          },
          onError: (errorCode, message) {
            if (kDebugMode) {
              print('네이버 로그인 에러 - Code: $errorCode, Message: $message');
            }
            completer.completeError(Exception('네이버 로그인 에러: $message'));
          },
        ),
      );
      
      return await completer.future;
      
    } catch (error) {
      if (kDebugMode) {
        print('네이버 로그인 예외: $error');
      }
      rethrow;
    }
  }

  // 네이버 로그아웃
  Future<void> logout() async {
    try {
      await NaverLoginSDK.logout();
      if (kDebugMode) {
        print('네이버 로그아웃 완료');
      }
    } catch (error) {
      if (kDebugMode) {
        print('네이버 로그아웃 실패: $error');
      }
    }
  }

  // 네이버 연결 끊기 (회원 탈퇴)
  Future<void> unlink() async {
    try {
      await NaverLoginSDK.release();
      if (kDebugMode) {
        print('네이버 연결 끊기 완료');
      }
    } catch (error) {
      if (kDebugMode) {
        print('네이버 연결 끊기 실패: $error');
      }
    }
  }
  
  // Mock 네이버 로그인 (개발용)
  Future<Map<String, dynamic>?> mockNaverLogin() async {
    try {
      if (kDebugMode) {
        print('Mock 네이버 로그인 시작');
      }
      
      // 개발 환경에서 테스트용 Mock 토큰 사용
      final mockAccessToken = 'mock_naver_access_token_${DateTime.now().millisecondsSinceEpoch}';
      
      // 백엔드 서버로 네이버 토큰 전송하여 JWT 토큰 받기
      final response = await _dio.post(
        '/oauth2/token',
        data: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'subject_token': mockAccessToken,
          'subject_token_type': 'urn:ietf:params:oauth:token-type:access_token',
          'scope': 'openid profile email api.read api.write',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': 'Basic ${AppConfig.getMobileClientCredentials()}',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (kDebugMode) {
          print('Mock 네이버 토큰 교환 성공: ${response.data}');
        }
        return response.data;
      }
      
    } catch (error) {
      if (kDebugMode) {
        print('Mock 네이버 로그인 실패 $error');
      }
      rethrow;
    }
    
    return null;
  }

  // Static login 메서드 추가
  static Future<Map<String, dynamic>?> login() async {
    try {
      final instance = NaverLoginService();
      
      // 네이티브 네이버 로그인 사용
      final result = await instance.loginWithNaver();
      if (result != null) {
        return {
          'success': true,
          'accessToken': result['access_token'],
          'refreshToken': result['refresh_token'],
        };
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Naver login error: $e');
      }
      return null;
    }
  }
}