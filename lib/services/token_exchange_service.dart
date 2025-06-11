import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
// import 'package:naver_login_sdk/naver_login_sdk.dart'; // API 문제로 임시 제거
import '../config/app_config.dart';
import 'naver_login_service.dart';

class TokenExchangeService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: AppConfig.googleWebClientId,
    // 디버그 목적으로 추가 설정
    // 기본적으로 Google Play Services가 필요하다는 메시지가 나올 수 있음
  );
  
  /// Google Play Services 사용 가능 여부 확인
  static Future<bool> isGooglePlayServicesAvailable() async {
    try {
      // GoogleSignIn의 isAvailable() 메서드로 확인
      final isAvailable = await _googleSignIn.isSignedIn();
      debugPrint('🔍 Google Play Services 확인 중...');
      return true; // 기본적으로 true 반환, 실제 에러는 signIn()에서 확인
    } catch (e) {
      debugPrint('❌ Google Play Services 확인 실패: $e');
      return false;
    }
  }
  
  /// Google Sign-In을 통해 ID Token을 받고 Spring Authorization Server 토큰으로 교환
  static Future<Map<String, dynamic>?> authenticateWithGoogle() async {
    try {
      debugPrint('🚀 Google 로그인 시작...');
      
      // 0. Google Play Services 사용 가능 여부 확인
      debugPrint('🔍 Google Play Services 확인 중...');
      final isAvailable = await isGooglePlayServicesAvailable();
      if (!isAvailable) {
        debugPrint('❌ Google Play Services를 사용할 수 없습니다');
        return null;
      }
      
      // 1. Google Sign-In
      debugPrint('🔄 이전 세션 정리 중...');
      await _googleSignIn.signOut(); // 이전 세션 정리
      
      debugPrint('📱 Google 로그인 UI 호출 중...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ 사용자가 Google 로그인을 취소했습니다');
        return null;
      }
      
      debugPrint('✅ Google 계정 선택 완료: ${googleUser.email}');
      
      // 2. Google 인증 정보 가져오기
      debugPrint('🔑 Google 인증 토큰 요청 중...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        debugPrint('Failed to get ID token from Google');
        return null;
      }
      
      debugPrint('Got Google ID token, exchanging for server token...');
      
      // 3. Token Exchange 요청
      // Client credentials for authentication
      final clientId = 'mobile-client';
      final clientSecret = 'mobile-secret';
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      
      final response = await http.post(
        Uri.parse('${AppConfig.authServerUrl}/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'subject_token': googleAuth.idToken!,
          'subject_token_type': 'urn:ietf:params:oauth:token-type:id_token',
          'scope': 'openid profile email api.read api.write',
        },
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Token exchange response status: ${response.statusCode}');
      debugPrint('Token exchange response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        debugPrint('Successfully exchanged tokens');
        return tokenData;
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        
        // 에러 응답 파싱
        try {
          final error = jsonDecode(response.body);
          debugPrint('Error: ${error['error']}, Description: ${error['error_description']}');
        } catch (e) {
          debugPrint('Failed to parse error response');
        }
        
        return null;
      }
      
    } catch (e) {
      debugPrint('❌ Google 인증 중 오류 발생: $e');
      debugPrint('❌ 오류 타입: ${e.runtimeType}');
      if (e.toString().contains('GoogleSignIn')) {
        debugPrint('❌ GoogleSignIn SDK 설정 문제일 가능성이 높습니다');
        debugPrint('   - google-services.json 파일 확인 필요');
        debugPrint('   - SHA-1 인증서 해시 확인 필요');
        debugPrint('   - Google Cloud Console 설정 확인 필요');
      }
      return null;
    }
  }
  
  /// Google ID Token을 서버 토큰으로 교환 (Google 로그인 없이)
  static Future<Map<String, dynamic>?> exchangeGoogleToken(String idToken) async {
    try {
      debugPrint('🔄 Google ID Token을 서버 토큰으로 교환 중...');
      
      // Client credentials for authentication
      final clientId = 'mobile-client';
      final clientSecret = 'mobile-secret';
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      
      final response = await http.post(
        Uri.parse('${AppConfig.authServerUrl}/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'subject_token': idToken,
          'subject_token_type': 'urn:ietf:params:oauth:token-type:id_token',
          'scope': 'openid profile email api.read api.write',
        },
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Token exchange response status: ${response.statusCode}');
      debugPrint('Token exchange response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        debugPrint('Successfully exchanged tokens');
        return tokenData;
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Token exchange error: $e');
      return null;
    }
  }
  
  /// Kakao 토큰을 서버 토큰으로 교환 (Kakao 로그인 없이)
  static Future<Map<String, dynamic>?> exchangeKakaoToken(String token, bool isIdToken) async {
    try {
      debugPrint('🔄 Kakao 토큰을 서버 토큰으로 교환 중...');
      
      // Client credentials for authentication
      final clientId = 'mobile-client';
      final clientSecret = 'mobile-secret';
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      
      final subjectTokenType = isIdToken 
          ? 'urn:ietf:params:oauth:token-type:id_token'
          : 'urn:ietf:params:oauth:token-type:access_token';
      
      final response = await http.post(
        Uri.parse('${AppConfig.authServerUrl}/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'subject_token': token,
          'subject_token_type': subjectTokenType,
          'subject_issuer': 'kakao',
          'scope': 'openid profile email api.read api.write',
        },
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Token exchange response status: ${response.statusCode}');
      debugPrint('Token exchange response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        debugPrint('Successfully exchanged tokens');
        return tokenData;
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Token exchange error: $e');
      return null;
    }
  }
  
  /// Naver Access Token을 서버 토큰으로 교환 (Naver 로그인 없이)
  static Future<Map<String, dynamic>?> exchangeNaverToken(String accessToken) async {
    try {
      debugPrint('🔄 Naver Access Token을 서버 토큰으로 교환 중...');
      
      // Client credentials for authentication
      final clientId = 'mobile-client';
      final clientSecret = 'mobile-secret';
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      
      final response = await http.post(
        Uri.parse('${AppConfig.authServerUrl}/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'subject_token': accessToken,
          'subject_token_type': 'urn:ietf:params:oauth:token-type:access_token',
          'subject_issuer': 'naver',
          'scope': 'openid profile email api.read api.write',
        },
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Token exchange response status: ${response.statusCode}');
      debugPrint('Token exchange response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        debugPrint('Successfully exchanged tokens');
        return tokenData;
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Token exchange error: $e');
      return null;
    }
  }
  
  /// Refresh Token으로 새로운 Access Token 받기
  static Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      // Client credentials for authentication
      final clientId = 'mobile-client';
      final clientSecret = 'mobile-secret';
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      
      final response = await http.post(
        Uri.parse('${AppConfig.authServerUrl}/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Token refresh failed: ${response.body}');
        return null;
      }
      
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }
  
  /// 카카오 로그인을 통해 Access Token을 받고 Spring Authorization Server 토큰으로 교환
  static Future<Map<String, dynamic>?> authenticateWithKakao() async {
    try {
      debugPrint('Starting Kakao authentication...');
      
      // 1. 카카오 로그인
      bool isTalkInstalled = await isKakaoTalkInstalled();
      
      OAuthToken token;
      
      if (isTalkInstalled) {
        // 카카오톡으로 로그인
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          debugPrint('카카오톡으로 로그인 성공');
        } catch (error) {
          debugPrint('카카오톡으로 로그인 실패 $error');
          // 카카오톡 로그인 실패 시 카카오 계정으로 로그인
          debugPrint('카카오 계정으로 로그인 시도...');
          token = await UserApi.instance.loginWithKakaoAccount();
          debugPrint('카카오 계정 로그인 성공!');
        }
      } else {
        // 카카오 계정으로 로그인
        debugPrint('카카오 계정으로 로그인 시도...');
        token = await UserApi.instance.loginWithKakaoAccount();
        debugPrint('카카오 계정 로그인 성공!');
      }
      
      debugPrint('카카오 로그인 성공, access token 획득');
      debugPrint('Access Token: ${token.accessToken.substring(0, 20)}...');
      debugPrint('ID Token 존재 여부: ${token.idToken != null}');
      if (token.idToken != null) {
        debugPrint('ID Token: ${token.idToken!.substring(0, 20)}...');
      }
      
      // 2. 사용자 정보 가져오기 (디버그용)
      try {
        User user = await UserApi.instance.me();
        debugPrint('사용자 정보: 회원번호=${user.id}, 닉네임=${user.kakaoAccount?.profile?.nickname}, 이메일=${user.kakaoAccount?.email}');
      } catch (e) {
        debugPrint('사용자 정보 요청 실패: $e');
      }
      
      // 3. Token Exchange 요청
      // Client credentials for authentication
      final clientId = 'mobile-client';
      final clientSecret = 'mobile-secret';
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      
      // ID Token이 있으면 ID Token으로, 없으면 Access Token으로 교환
      final subjectToken = token.idToken ?? token.accessToken;
      final subjectTokenType = token.idToken != null 
          ? 'urn:ietf:params:oauth:token-type:id_token'
          : 'urn:ietf:params:oauth:token-type:access_token';
      
      debugPrint('Token Exchange URL: ${AppConfig.authServerUrl}/oauth2/token');
      debugPrint('Subject Token Type: $subjectTokenType');
      debugPrint('Subject Token: ${subjectToken.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse('${AppConfig.authServerUrl}/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
          'subject_token': subjectToken,
          'subject_token_type': subjectTokenType,
          'scope': 'openid profile email api.read api.write',
        },
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Kakao token exchange response status: ${response.statusCode}');
      debugPrint('Kakao token exchange response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        debugPrint('Successfully exchanged Kakao tokens');
        debugPrint('Access Token received: ${tokenData['access_token']?.toString().substring(0, 20)}...');
        debugPrint('Token Type: ${tokenData['token_type']}');
        debugPrint('Expires In: ${tokenData['expires_in']}');
        return tokenData;
      } else {
        debugPrint('Kakao token exchange failed: ${response.body}');
        
        // 에러 응답 파싱
        try {
          final error = jsonDecode(response.body);
          debugPrint('Error: ${error['error']}, Description: ${error['error_description']}');
        } catch (e) {
          debugPrint('Failed to parse error response');
        }
        
        return null;
      }
      
    } catch (e) {
      debugPrint('Error during Kakao authentication: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('Exception message: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// 네이버 로그인을 통해 Access Token을 받고 Spring Authorization Server 토큰으로 교환
  static Future<Map<String, dynamic>?> authenticateWithNaver() async {
    try {
      debugPrint('Starting Naver authentication...');
      
      // 네이버 네이티브 로그인 사용
      final naverResult = await NaverLoginService.login();
      if (naverResult == null || naverResult['success'] != true) {
        debugPrint('Naver login failed or cancelled');
        return null;
      }
      
      // 네이버에서 받은 JWT 토큰 반환
      return {
        'access_token': naverResult['accessToken'],
        'refresh_token': naverResult['refreshToken'],
        'token_type': 'Bearer',
      };
      
    } catch (e) {
      debugPrint('Error during Naver authentication: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('Exception message: ${e.toString()}');
      }
      return null;
    }
  }

  /// 로그아웃 (Google, Kakao, Naver 모두)
  static Future<void> signOut() async {
    // Google 로그아웃
    await _googleSignIn.signOut();
    
    // 카카오 로그아웃
    try {
      await UserApi.instance.logout();
      debugPrint('카카오 로그아웃 성공');
    } catch (error) {
      debugPrint('카카오 로그아웃 실패: $error');
    }
    
    // 네이버 로그아웃
    try {
      await NaverLoginService().logout();
      debugPrint('네이버 로그아웃 처리됨');
    } catch (error) {
      debugPrint('네이버 로그아웃 실패: $error');
    }
  }
}