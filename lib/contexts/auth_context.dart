import 'package:flutter/foundation.dart';

/// 인증 방법 열거형
enum AuthMethod { native, oauth2 }

/// 간단한 인증 컨텍스트 클래스
class AuthContextState {
  final bool isAuthenticated;
  final String? token;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final bool isLoading;
  final String? error;

  const AuthContextState({
    this.isAuthenticated = false,
    this.token,
    this.userId,
    this.userEmail,
    this.userName,
    this.isLoading = false,
    this.error,
  });

  AuthContextState copyWith({
    bool? isAuthenticated,
    String? token,
    String? userId,
    String? userEmail,
    String? userName,
    bool? isLoading,
    String? error,
  }) {
    return AuthContextState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 인증 컨텍스트 Provider (현재는 Provider 패턴 사용하므로 별도 구현 없이 AuthProvider 사용)
/// 
/// 이 파일은 기존 Riverpod 기반 코드와의 호환성을 위해 유지되며,
/// 실제 구현은 providers/auth_provider.dart의 AuthProvider를 사용합니다.

// 글로벌 변수로 현재 인증 방법 저장 (임시)
AuthMethod _currentAuthMethod = AuthMethod.oauth2;

/// 현재 인증 방법 가져오기
AuthMethod getCurrentAuthMethod() {
  return _currentAuthMethod;
}

/// 인증 방법 설정
void setAuthMethod(AuthMethod method) {
  _currentAuthMethod = method;
}

/// OAuth2 로그인 처리를 위한 더미 함수
Future<void> handleOAuth2Login() async {
  // TODO: OAuth2 로그인 구현
  if (kDebugMode) {
    print('OAuth2 로그인 시작...');
  }
}

/// 카카오 로그인 처리를 위한 더미 함수
Future<void> handleKakaoLogin() async {
  // TODO: 카카오 로그인 구현
  if (kDebugMode) {
    print('카카오 로그인 시작...');
  }
}

/// 네이버 로그인 처리를 위한 더미 함수
Future<void> handleNaverLogin() async {
  // TODO: 네이버 로그인 구현
  if (kDebugMode) {
    print('네이버 로그인 시작...');
  }
}

/// 구글 로그인 처리를 위한 더미 함수
Future<void> handleGoogleLogin() async {
  // TODO: 구글 로그인 구현
  if (kDebugMode) {
    print('구글 로그인 시작...');
  }
}