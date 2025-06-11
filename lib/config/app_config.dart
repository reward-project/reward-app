import 'package:reward_common/config/app_config.dart' as common;

/// reward_app을 위한 AppConfig 래퍼
/// 기존 코드와의 호환성을 위해 static 접근을 제공합니다.
class AppConfig {
  static final _instance = common.AppConfig.instance;
  
  static common.Environment get _environment => _instance.environment;
  
  static void initialize(common.Environment env) {
    // 이미 main.dart에서 초기화됨
  }
  
  static bool get isDesktop => _instance.isDesktop;
  
  static String get apiBaseUrl => _instance.apiBaseUrl;
  
  static String get authServerUrl => _instance.authServerUrl;
  
  static String get apiPath => _instance.apiPath;
  
  static String get oauth2ClientId => _instance.oauth2ClientId;
  
  static String get oauth2RedirectUri => _instance.oauth2RedirectUri;
  
  static bool get usePKCE => _instance.usePKCE;
  
  static String get googleWebClientId => _instance.googleClientId;
  
  static String get kakaoNativeAppKey => _instance.kakaoNativeAppKey;
  
  static String get kakaoJavaScriptKey => _instance.kakaoJavaScriptKey;
  
  static String get naverClientId => _instance.naverClientId;
  
  static String get naverClientSecret => _instance.naverClientSecret;
  
  static String get naverClientName => _instance.naverClientName;
  
  // 일반 앱 전용 getter들
  static String get businessDomain => _instance.businessDomain;
  
  static bool get isDebug => _instance.isDebug;
  
  static String get rewardApiUrl => _instance.rewardApiUrl;
  
  static String get edusenseAuthUrl => _instance.edusenseAuthUrl;
  
  static String get edusenseClientId => _instance.edusenseClientId;
  
  static Map<String, String> getMobileClientCredentials() =>
      _instance.getMobileClientCredentials();
}

// 기존 코드와의 호환성을 위한 Environment export
typedef Environment = common.Environment;