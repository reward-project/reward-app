import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import 'package:reward_common/models/token_dto.dart';
import 'token_exchange_service.dart';

/// 구글 로그인 전용 서비스
class GoogleLoginService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: AppConfig.googleWebClientId,
  );

  /// 구글 로그인 수행
  static Future<TokenDto?> signIn() async {
    try {
      if (kDebugMode) print('🚀 Google 로그인 시작...');
      
      // 이전 세션 정리
      await _googleSignIn.signOut();
      
      if (kDebugMode) print('📱 Google 로그인 UI 호출 중...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) print('❌ 사용자가 Google 로그인을 취소했습니다');
        return null;
      }
      
      if (kDebugMode) print('✅ Google 계정 선택 완료: ${googleUser.email}');
      
      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        if (kDebugMode) print('❌ Google ID Token을 가져올 수 없습니다');
        return null;
      }
      
      if (kDebugMode) print('🔑 Google ID Token 획득, 서버 토큰 교환 중...');
      
      // 토큰 교환 수행 (이미 받은 ID Token을 전달)
      final result = await TokenExchangeService.exchangeGoogleToken(googleAuth.idToken!);
      
      if (result != null) {
        if (kDebugMode) print('✅ 토큰 교환 성공');
        return TokenDto(
          accessToken: result['access_token'] as String,
          refreshToken: result['refresh_token'] as String?,
        );
      } else {
        if (kDebugMode) print('❌ 토큰 교환 실패');
        return null;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google 로그인 중 오류 발생: $e');
        print('❌ 오류 타입: ${e.runtimeType}');
        if (e.toString().contains('GoogleSignIn')) {
          print('❌ GoogleSignIn SDK 설정 문제일 가능성이 높습니다');
          print('   - google-services.json 파일 확인 필요');
          print('   - SHA-1 인증서 해시 확인 필요');
          print('   - Google Cloud Console 설정 확인 필요');
        }
      }
      return null;
    }
  }

  /// 구글 로그아웃
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (kDebugMode) print('✅ Google 로그아웃 완료');
    } catch (e) {
      if (kDebugMode) print('❌ Google 로그아웃 실패: $e');
    }
  }

  /// 현재 로그인 상태 확인
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      if (kDebugMode) print('❌ Google 로그인 상태 확인 실패: $e');
      return false;
    }
  }

  /// 현재 로그인된 사용자 정보 가져오기
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return _googleSignIn.currentUser;
    } catch (e) {
      if (kDebugMode) print('❌ Google 사용자 정보 가져오기 실패: $e');
      return null;
    }
  }
}