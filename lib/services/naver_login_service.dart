import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
// import 'package:naver_login_sdk/naver_login_sdk.dart';  // 임시 주석처리
import '../config/app_config.dart';

class NaverLoginService {
  static final NaverLoginService _instance = NaverLoginService._internal();
  factory NaverLoginService() => _instance;
  NaverLoginService._internal();

  late final Dio _dio;

  void init(Dio dio) {
    _dio = dio;
  }

  // 네이버 SDK 초기화 (임시 스텁)
  static Future<void> initializeNaverSDK() async {
    try {
      // await NaverLoginSDK.initialize(  // 임시 주석처리
      //   clientId: '2aGPAheEeSLvfbHOHDIB',
      //   clientSecret: '2aGPAheEeSLvfbHOHDIB',
      //   clientName: 'Reward App',
      // );
      if (kDebugMode) {
        print('네이버 로그인 SDK 초기화 완료 (스텁)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('네이버 로그인 SDK 초기화 실패: $e');
      }
    }
  }

  // 네이버 네이티브 로그인 (임시 스텁)
  Future<Map<String, dynamic>?> loginWithNaver() async {
    try {
      if (kDebugMode) {
        print('네이버 네이티브 로그인 시작 (스텁)');
      }
      
      // 임시로 null 반환
      return null;
      
    } catch (error) {
      if (kDebugMode) {
        print('네이버 로그인 예외: $error');
      }
      rethrow;
    }
  }

  // 네이버 로그아웃 (임시 스텁)
  Future<void> logout() async {
    try {
      // await NaverLoginSDK.logout();  // 임시 주석처리
      if (kDebugMode) {
        print('네이버 로그아웃 완료 (스텁)');
      }
    } catch (error) {
      if (kDebugMode) {
        print('네이버 로그아웃 실패: $error');
      }
    }
  }

  // Static login 메서드 (임시 스텁)
  static Future<Map<String, dynamic>?> login() async {
    try {
      if (kDebugMode) {
        print('Naver login (스텁)');
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