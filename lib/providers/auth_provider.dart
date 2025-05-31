import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../services/token_exchange_service.dart';
import '../models/api_response.dart';
import '../models/token_dto.dart';
import '../services/dio_service.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  final BuildContext context;
  bool _isAuthenticated = false;
  String? _accessToken;
  String? _refreshToken;
  Timer? _refreshTimer;
  Map<String, dynamic>? _userInfo;
  bool _isInitialized = false;

  AuthProvider(this.context);

  bool get isAuthenticated => _isAuthenticated;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isInitialized => _isInitialized;

  UserInfo? get currentUser =>
      _userInfo != null ? UserInfo.fromJson(_userInfo!) : null;

  Future<UserInfo?> get user async {
    if (!_isAuthenticated) return null;
    if (_userInfo == null) {
      if (kDebugMode) {
        print('User info is null, fetching from server...');
      }
      return await fetchUserInfo();
    }
    return UserInfo.fromJson(_userInfo!);
  }

  Future<UserInfo?> fetchUserInfo() async {
    if (!_isAuthenticated) return null;

    try {
      // AuthServer의 userinfo 엔드포인트 사용
      final response = await Dio().get(
        '${AppConfig.authServerUrl}/userinfo',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );
      
      if (kDebugMode) {
        print('fetchUserInfo response: ${response.data}');
      }

      // OAuth2 userinfo 응답 형식에 맞게 파싱
      final userData = response.data as Map<String, dynamic>;
      
      // UserInfo 형식으로 변환
      final userInfo = {
        'id': userData['sub'] ?? userData['id'],
        'email': userData['email'],
        'name': userData['name'],
        'nickname': userData['nickname'] ?? userData['preferred_username'],
        'profileImage': userData['picture'] ?? userData['profileImage'],
        'role': userData['role'] ?? 'USER',
      };
      
      _userInfo = userInfo;
      notifyListeners();
      return UserInfo.fromJson(userInfo);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user info from authserver: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    }
    return null;
  }

  void startTokenRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
        const Duration(minutes: 15), // 15분 만료 토큰의 경우
        (_) => refreshAuthToken());
  }

  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final dio = DioService.instance;

      final response = await dio
          .post('/members/refresh', data: {'refreshToken': _refreshToken});

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => TokenDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await setTokens(
            accessToken: apiResponse.data?.accessToken,
            refreshToken: apiResponse.data?.refreshToken);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh error: $e');
      }
      await logout();
    }
    return false;
  }

  Future<void> setTokens({String? accessToken, String? refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _isAuthenticated = accessToken != null;

    if (accessToken != null) {
      startTokenRefreshTimer(); // 토큰 설정 시 자동 갱신 시작
    }

    if (kDebugMode) {
      print('Setting tokens:');
      print('Access Token: ${accessToken != null}');
      print('Refresh Token: ${refreshToken != null}');
    }

    if (kDebugMode) {
      print('Auth state after setting tokens:');
      print('isAuthenticated: $_isAuthenticated');
    }

    // refreshToken이 있을 때만 저장 (토큰 교환에서 refresh_token이 없을 수 있음)
    if (accessToken != null) {
      if (refreshToken != null) {
        await AuthService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        // refreshToken이 없는 경우 accessToken만 임시 저장
        if (kDebugMode) {
          print('RefreshToken is null, saving only accessToken for this session');
        }
      }
    }

    notifyListeners();
  }

  Future<void> logout() async {
    final currentRefreshToken = _refreshToken;
    _refreshTimer?.cancel();

    // 서버에 로그아웃 요청
    if (currentRefreshToken != null) {
      try {
        final dio = DioService.instance;
        await dio.post('/members/logout',
            data: {'refreshToken': currentRefreshToken});
      } catch (e) {
        if (kDebugMode) {
          print('Logout error: $e');
        }
      }
    }

    // 로컬 상태 초기화
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _userInfo = null;

    await AuthService.logout();
    notifyListeners();
  }

  // 초기 상태 로드
  Future<void> loadAuthState() async {
    // 저장소에서 토큰 확인
    final token = await AuthService.getToken();
    final refreshToken = await AuthService.getRefreshToken();
    _accessToken = token;
    _refreshToken = refreshToken;
    _isAuthenticated = token != null;
    notifyListeners();
  }

  // 앱 시작 시 호출되는 초기화 메서드
  Future<void> initializeAuth() async {
    final accessToken = await AuthService.getToken();
    final refreshToken = await AuthService.getRefreshToken();

    if (accessToken != null && refreshToken != null) {
      await setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    _isInitialized = true;
    notifyListeners();
  }

  // 별도의 초기화 메서드로 분리
  Future<void> initializeUserInfo() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_isAuthenticated && _userInfo == null) {
      try {
        final userInfo = await fetchUserInfo();
        if (userInfo != null) {
          _userInfo = userInfo.toJson();
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing user info: $e');
        }
      }
    }
  }

  /// 구글 로그인
  Future<bool> loginWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Google login...');
      }
      
      final tokenData = await TokenExchangeService.authenticateWithGoogle();
      
      if (tokenData != null) {
        await setTokens(
          accessToken: tokenData['access_token'],
          refreshToken: tokenData['refresh_token'],
        );
        
        if (kDebugMode) {
          print('Google login successful');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Google login failed: No token data');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google login error: $e');
      }
      return false;
    }
  }

  /// 카카오 로그인
  Future<bool> loginWithKakao() async {
    try {
      if (kDebugMode) {
        print('Starting Kakao login...');
      }
      
      final tokenData = await TokenExchangeService.authenticateWithKakao();
      
      if (tokenData != null) {
        await setTokens(
          accessToken: tokenData['access_token'],
          refreshToken: tokenData['refresh_token'],
        );
        
        if (kDebugMode) {
          print('Kakao login successful');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Kakao login failed: No token data');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Kakao login error: $e');
      }
      return false;
    }
  }

  /// 네이버 로그인
  Future<bool> loginWithNaver() async {
    try {
      if (kDebugMode) {
        print('Starting Naver login...');
      }
      
      final tokenData = await TokenExchangeService.authenticateWithNaver();
      
      if (tokenData != null) {
        await setTokens(
          accessToken: tokenData['access_token'],
          refreshToken: tokenData['refresh_token'],
        );
        
        if (kDebugMode) {
          print('Naver login successful');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Naver login failed: No token data');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Naver login error: $e');
      }
      return false;
    }
  }
}

class UserInfo {
  final String userId;
  final String userName;
  final String email;
  final String role;
  final String nickname;
  final String? profileImage;
  final DateTime? createdAt;

  UserInfo({
    required this.userId,
    required this.userName,
    required this.email,
    required this.role,
    required this.nickname,
    this.profileImage,
    this.createdAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('Parsing UserInfo from JSON: $json');
    }
    return UserInfo(
      userId: json['id']?.toString() ?? '',
      userName: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      nickname: json['nickname'],
      profileImage: json['profileImage'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'name': userName,
      'email': email,
      'role': role,
      'nickname': nickname,
      'profileImage': profileImage,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
