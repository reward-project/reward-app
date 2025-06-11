import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:reward_common/config/app_config.dart';

class ApiTestUtil {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// API 연결 테스트 실행
  static Future<Map<String, dynamic>> runConnectionTest() async {
    final appConfig = AppConfig.instance;
    Map<String, dynamic> results = {};
    
    if (kDebugMode) {
      print('🚀 Starting API Connection Test...');
      print('Environment: ${appConfig.environment}');
      print('App Type: ${appConfig.appType}');
    }

    // 1. AuthServer 테스트
    results['authServer'] = await _testEndpoint(
      'AuthServer',
      '${appConfig.authServerUrl}/actuator/health',
    );

    // 2. ConfigServer 테스트 (Windows 환경에서만)
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows)) {
      results['configServer'] = await _testEndpoint(
        'ConfigServer',
        'http://localhost:8888/actuator/health',
      );
    }

    // 3. Backend API 테스트
    results['backendApi'] = await _testEndpoint(
      'Backend API',
      '${appConfig.apiBaseUrl}/actuator/health',
    );

    // 4. OAuth2 Token Endpoint 테스트
    results['oauth2Token'] = await _testOAuth2Token(appConfig.authServerUrl);

    return results;
  }

  /// 개별 엔드포인트 테스트
  static Future<Map<String, dynamic>> _testEndpoint(String name, String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (kDebugMode) {
        print('✅ $name: Connected (${response.statusCode})');
      }
      
      return {
        'status': 'success',
        'statusCode': response.statusCode,
        'url': url,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ $name: ${e.toString()}');
      }
      
      return {
        'status': 'failed',
        'error': e.toString(),
        'url': url,
      };
    }
  }

  /// OAuth2 토큰 엔드포인트 테스트
  static Future<Map<String, dynamic>> _testOAuth2Token(String authServerUrl) async {
    try {
      final response = await _dio.post(
        '$authServerUrl/oauth2/token',
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null,
        ),
        data: 'grant_type=client_credentials&client_id=test&client_secret=test',
      );
      
      if (kDebugMode) {
        if (response.statusCode == 401) {
          print('⚠️  OAuth2 Token: Unauthorized (expected for test credentials)');
        } else if (response.statusCode == 200) {
          print('✅ OAuth2 Token: Success');
        } else {
          print('⚠️  OAuth2 Token: Status ${response.statusCode}');
        }
      }
      
      return {
        'status': response.statusCode == 200 || response.statusCode == 401 ? 'accessible' : 'error',
        'statusCode': response.statusCode,
        'endpoint': '$authServerUrl/oauth2/token',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ OAuth2 Token: ${e.toString()}');
      }
      
      return {
        'status': 'failed',
        'error': e.toString(),
        'endpoint': '$authServerUrl/oauth2/token',
      };
    }
  }

  /// 결과 요약 출력
  static void printSummary(Map<String, dynamic> results) {
    if (!kDebugMode) return;
    
    print('\n📊 API Connection Test Summary:');
    print('─' * 50);
    
    results.forEach((key, value) {
      String status = value['status'] ?? 'unknown';
      String emoji = status == 'success' || status == 'accessible' ? '✅' : '❌';
      print('$emoji $key: $status');
      if (value['error'] != null) {
        print('   Error: ${value['error']}');
      }
    });
    
    print('─' * 50);
  }
}