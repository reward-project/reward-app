import 'dart:io';
import '../lib/utils/api_test_util.dart';
import 'package:reward_common/config/app_config.dart' as common_config;

/// 독립적인 API 연결 테스트 스크립트
void main() async {
  print('🚀 Starting standalone API Connection Test...\n');
  
  // AppConfig 초기화
  common_config.AppConfig.initialize(
    env: common_config.Environment.dev,
    appType: common_config.AppType.app,
  );
  
  final appConfig = common_config.AppConfig.instance;
  
  print('=== Configuration ===');
  print('Environment: ${appConfig.environment}');
  print('App Type: ${appConfig.appType}');
  print('API Base URL: ${appConfig.apiBaseUrl}');
  print('Auth Server URL: ${appConfig.authServerUrl}');
  print('====================\n');
  
  // API 연결 테스트 실행
  try {
    final results = await ApiTestUtil.runConnectionTest();
    
    // 결과 출력
    ApiTestUtil.printSummary(results);
    
    // 전체 결과 판정
    int successCount = 0;
    int failedCount = 0;
    
    results.forEach((key, value) {
      if (value['status'] == 'success' || value['status'] == 'accessible') {
        successCount++;
      } else if (value['status'] == 'failed') {
        failedCount++;
      }
    });
    
    print('\n=== Final Result ===');
    print('✅ Success: $successCount');
    print('❌ Failed: $failedCount');
    print('===================\n');
    
    if (failedCount == 0) {
      print('🎉 All API connections are working properly!');
      exit(0);
    } else {
      print('⚠️  Some API connections failed. Please check your backend services.');
      exit(1);
    }
  } catch (e) {
    print('❌ Error during test: $e');
    exit(2);
  }
}