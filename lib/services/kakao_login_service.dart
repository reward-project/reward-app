import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:reward_common/models/token_dto.dart';
import 'token_exchange_service.dart';

/// 카카오 로그인 전용 서비스
class KakaoLoginService {
  
  /// 카카오 로그인 수행
  static Future<TokenDto?> signIn() async {
    try {
      if (kDebugMode) print('🟡 카카오 로그인 시작...');
      
      // 카카오톡 설치 여부 확인
      bool isTalkInstalled = await isKakaoTalkInstalled();
      if (kDebugMode) print('📱 카카오톡 설치 여부: $isTalkInstalled');
      
      OAuthToken token;
      
      if (isTalkInstalled) {
        // 카카오톡으로 로그인
        try {
          if (kDebugMode) print('📱 카카오톡으로 로그인 시도...');
          token = await UserApi.instance.loginWithKakaoTalk();
          if (kDebugMode) print('✅ 카카오톡 로그인 성공');
        } catch (error) {
          if (kDebugMode) print('❌ 카카오톡 로그인 실패: $error');
          // 카카오톡 로그인 실패 시 카카오 계정으로 로그인
          if (kDebugMode) print('🌐 카카오 계정으로 로그인 시도...');
          token = await UserApi.instance.loginWithKakaoAccount();
          if (kDebugMode) print('✅ 카카오 계정 로그인 성공');
        }
      } else {
        // 카카오 계정으로 로그인
        if (kDebugMode) print('🌐 카카오 계정으로 로그인 시도...');
        token = await UserApi.instance.loginWithKakaoAccount();
        if (kDebugMode) print('✅ 카카오 계정 로그인 성공');
      }
      
      if (kDebugMode) {
        print('🔑 카카오 Access Token 획득: ${token.accessToken.substring(0, 20)}...');
        print('🆔 ID Token 존재 여부: ${token.idToken != null}');
        if (token.idToken != null) {
          print('🆔 ID Token: ${token.idToken!.substring(0, 20)}...');
        }
      }
      
      // 사용자 정보 가져오기 (디버그용)
      try {
        User user = await UserApi.instance.me();
        if (kDebugMode) {
          print('👤 카카오 사용자 정보:');
          print('   회원번호: ${user.id}');
          print('   닉네임: ${user.kakaoAccount?.profile?.nickname}');
          print('   이메일: ${user.kakaoAccount?.email}');
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ 사용자 정보 요청 실패: $e');
      }
      
      if (kDebugMode) print('🔄 서버 토큰 교환 중...');
      
      // 토큰 교환 수행 (이미 받은 토큰을 전달)
      // ID Token이 있으면 ID Token으로, 없으면 Access Token으로 교환
      final subjectToken = token.idToken ?? token.accessToken;
      final isIdToken = token.idToken != null;
      
      final result = await TokenExchangeService.exchangeKakaoToken(subjectToken, isIdToken);
      
      if (result != null) {
        if (kDebugMode) print('✅ 카카오 토큰 교환 성공');
        return TokenDto(
          accessToken: result['access_token'] as String,
          refreshToken: result['refresh_token'] as String?,
        );
      } else {
        if (kDebugMode) print('❌ 카카오 토큰 교환 실패');
        return null;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ 카카오 로그인 중 오류 발생: $e');
        print('❌ 오류 타입: ${e.runtimeType}');
        if (e.toString().contains('KakaoException')) {
          print('❌ 카카오 SDK 설정 문제일 가능성이 높습니다');
          print('   - 카카오 네이티브 앱 키 확인 필요');
          print('   - 카카오 개발자 콘솔 설정 확인 필요');
          print('   - 패키지명 및 키 해시 확인 필요');
        }
      }
      return null;
    }
  }

  /// 카카오 로그아웃
  static Future<void> signOut() async {
    try {
      await UserApi.instance.logout();
      if (kDebugMode) print('✅ 카카오 로그아웃 성공');
    } catch (error) {
      if (kDebugMode) print('❌ 카카오 로그아웃 실패: $error');
    }
  }

  /// 카카오 연결 끊기 (앱 연동 해제)
  static Future<void> unlink() async {
    try {
      await UserApi.instance.unlink();
      if (kDebugMode) print('✅ 카카오 연결 끊기 성공');
    } catch (error) {
      if (kDebugMode) print('❌ 카카오 연결 끊기 실패: $error');
    }
  }

  /// 현재 로그인된 사용자 정보 가져오기
  static Future<User?> getCurrentUser() async {
    try {
      return await UserApi.instance.me();
    } catch (e) {
      if (kDebugMode) print('❌ 카카오 사용자 정보 가져오기 실패: $e');
      return null;
    }
  }

  /// 토큰 정보 확인
  static Future<AccessTokenInfo?> getTokenInfo() async {
    try {
      return await UserApi.instance.accessTokenInfo();
    } catch (e) {
      if (kDebugMode) print('❌ 카카오 토큰 정보 확인 실패: $e');
      return null;
    }
  }
}