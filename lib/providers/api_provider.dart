import 'package:flutter/material.dart';
import 'package:reward_common/reward_common.dart';
import '../config/app_config.dart';
import 'auth_provider_extended.dart';
import 'package:provider/provider.dart';

class ApiProvider extends ChangeNotifier {
  late ApiService _apiService;
  
  ApiService get apiService => _apiService;
  
  ApiProvider() {
    _initApiService();
  }
  
  void _initApiService() {
    _apiService = ApiService(
      baseUrl: '${AppConfig.apiBaseUrl}${AppConfig.apiPath}',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }
  
  // 토큰 업데이트를 위한 메서드
  void updateAuthToken(String? token) {
    if (token != null) {
      _apiService.dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _apiService.dio.options.headers.remove('Authorization');
    }
    notifyListeners();
  }
  
  // 언어 설정 업데이트
  void updateLanguage(String locale) {
    _apiService.dio.options.headers['Accept-Language'] = locale;
    notifyListeners();
  }
}

// Helper function to get ApiService from context
extension ApiProviderExtension on BuildContext {
  ApiService get apiService {
    return Provider.of<ApiProvider>(this, listen: false).apiService;
  }
}