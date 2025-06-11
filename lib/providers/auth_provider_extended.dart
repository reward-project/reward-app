import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reward_common/providers/auth_provider.dart';
import 'package:reward_common/services/api_service.dart';
import '../services/auth_service.dart';
import '../services/google_login_service.dart';
import '../services/kakao_login_service.dart';
import '../services/naver_login_service.dart';
import '../config/app_config.dart';

/// reward_app을 위한 확장 AuthProvider
class AppAuthProvider extends AuthProvider {
  AppAuthProvider(BuildContext context) : super(
    context,
    AuthProviderConfig(
      authServerUrl: AppConfig.authServerUrl,
      redirectUri: kIsWeb 
        ? 'http://localhost:46152/oauth2/redirect'
        : 'http://localhost:8766/auth/callback',
      clientId: 'app-client',
      onTokenSet: (token) async {
        // ApiService에 토큰 설정
        final apiService = ApiService();
        await apiService.setToken(token);
      },
      onLogout: () async {
        // ApiService의 토큰도 제거
        final apiService = ApiService();
        await apiService.setToken(null);
      },
      supportsSocialLogin: true,
    ),
  );

  // Backward compatibility getters for reward_app
  String? get userId => currentUser?.userId;
  String? get userEmail => currentUser?.email;
  String? get userName => currentUser?.userName;
  String? get userType => currentUser?.userType ?? 'customer';

  // user getter는 AuthProvider에서 상속받아 사용

  /// Google 로그인
  Future<bool> loginWithGoogle() async {
    try {
      print('🔵 AuthProvider: Google 로그인 시작');
      
      final tokenDto = await GoogleLoginService.signIn();
      
      if (tokenDto != null) {
        print('✅ AuthProvider: Google 로그인 성공, 토큰 설정 중...');
        
        await setTokens(
          accessToken: tokenDto.accessToken,
          refreshToken: tokenDto.refreshToken,
        );
        
        return true;
      } else {
        print('❌ AuthProvider: Google 로그인 실패 - 토큰이 null');
        return false;
      }
    } catch (e) {
      print('❌ AuthProvider Google login error: $e');
      return false;
    }
  }

  /// Kakao 로그인
  Future<bool> loginWithKakao() async {
    try {
      print('🟡 AuthProvider: Kakao 로그인 시작');
      
      final tokenDto = await KakaoLoginService.signIn();
      
      if (tokenDto != null) {
        print('✅ AuthProvider: Kakao 로그인 성공, 토큰 설정 중...');
        
        await setTokens(
          accessToken: tokenDto.accessToken,
          refreshToken: tokenDto.refreshToken,
        );
        
        // Clear any stored PKCE parameters after successful login
        await AuthService.clearPKCEParameters();
        
        return true;
      } else {
        print('❌ AuthProvider: Kakao 로그인 실패 - 토큰이 null');
        return false;
      }
    } catch (e) {
      print('❌ AuthProvider Kakao login error: $e');
      return false;
    }
  }

  /// Naver 로그인
  Future<bool> loginWithNaver() async {
    try {
      print('🟢 AuthProvider: Naver 로그인 시작');
      
      final tokenDto = await NaverLoginService.login();
      
      if (tokenDto != null) {
        print('✅ AuthProvider: Naver 로그인 성공, 토큰 설정 중...');
        
        await setTokens(
          accessToken: tokenDto['accessToken'],
          refreshToken: tokenDto['refreshToken'],
        );
        
        return true;
      } else {
        print('❌ AuthProvider: Naver 로그인 실패 - 토큰이 null');
        return false;
      }
    } catch (e) {
      print('❌ AuthProvider Naver login error: $e');
      return false;
    }
  }

  /// 네이티브 로그인
  Future<bool> login(String email, String password) async {
    try {
      // TODO: API 로그인 구현
      // 임시로 성공으로 처리
      await setTokens(
        accessToken: 'temp_access_token',
        refreshToken: 'temp_refresh_token',
      );
      
      // 임시 사용자 정보 설정
      final tempUserInfo = {
        'id': '1',
        'email': email,
        'name': email.split('@')[0],
        'userType': 'customer',
      };
      
      // _userInfo를 직접 설정
      await updateUserInfo(
        userId: tempUserInfo['id']!,
        userEmail: tempUserInfo['email']!,
        userName: tempUserInfo['name']!,
        userType: tempUserInfo['userType']!,
      );
      
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// 회원가입
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // TODO: API 회원가입 구현
      // 임시로 성공으로 처리하고 자동 로그인
      return await login(email, password);
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  /// 사용자 정보 업데이트
  Future<void> updateUserInfo({
    required String userId,
    required String userEmail,
    required String userName,
    required String userType,
  }) async {
    try {
      // userInfo를 Map으로 직접 설정
      final userInfoMap = {
        'id': userId,
        'email': userEmail,
        'name': userName,
        'userType': userType,
      };
      
      // Protected field access through reflection or custom setter
      // Since _userInfo is private, we need to use the parent's method
      await fetchUserInfo(); // This will update _userInfo
      
      // For now, save to SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('user_email', userEmail);
      await prefs.setString('user_name', userName);
      await prefs.setString('user_type', userType);
      
      notifyListeners();
    } catch (e) {
      print('Update user info error: $e');
    }
  }
}

// Provide a typedef for backward compatibility
typedef UserInfo = Map<String, dynamic>;