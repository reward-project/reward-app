import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:io' show Platform;
import 'dart:convert';

enum Environment {
  dev,
  prod,
}

class AppConfig {
  static Environment _environment = Environment.dev;

  static String get businessDomain => _environment == Environment.prod
      ? 'https://business.reward-factory.shop'
      : 'http://localhost:46152';
  static void initialize(Environment env) {
    _environment = env;
  }
  
  static bool get isDebug => _environment == Environment.dev;

  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static String get apiBaseUrl {
    if (_environment == Environment.dev && !kIsWeb) {
      if (Platform.isAndroid) {
        // Windows 호스트 서버에 접근
        return 'http://192.168.219.112:8882'; // Reward server port
      }
    }

    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8882', // Reward server port
    );
  }

  // AuthServer configuration
  static String get authServerUrl {
    if (_environment == Environment.prod) {
      return 'https://auth.edu-sense.shop';
    }
    
    if (!kIsWeb && Platform.isAndroid) {
      // Windows 호스트 서버에 접근
      return 'http://192.168.219.112:8881'; // AuthServer
    }
    
    return 'http://localhost:8881'; // Development AuthServer
  }

  static String get apiPath => '/api/v1';

  // OAuth2 client configuration
  static String get oauth2ClientId => 'reward-client';
  
  // OAuth2 redirect URI
  static String get oauth2RedirectUri {
    if (_environment == Environment.prod) {
      return 'https://reward-factory.shop/oauth2/redirect';
    }
    
    if (kIsWeb) {
      return 'http://localhost:46151/oauth2/redirect';
    }
    
    // Mobile app uses local server callback
    return 'http://localhost:8765/auth/callback';
  }

  static String get rewardAppUrl => _environment == Environment.prod
      ? 'https://app.reward-factory.shop'
      : 'http://localhost:46151';
      
  // PKCE configuration (required for mobile public clients)
  static bool get usePKCE => true;
  
  // Google OAuth2 Web Client ID (for mobile apps)
  static String get googleWebClientId {
    // .env 파일에서 가져온 값을 사용
    return '133048024494-v9q4qimam6cl70set38o8tdbj3mcr0ss.apps.googleusercontent.com';
  }

  // Kakao SDK configuration (모바일 전용)
  static String get kakaoNativeAppKey {
    return const String.fromEnvironment(
      'KAKAO_NATIVE_APP_KEY',
      defaultValue: '69383ae32e0f8936472078d4f6563666',
    );
  }
  
  // Naver SDK configuration (모바일 전용)
  static String get naverClientId {
    return const String.fromEnvironment(
      'NAVER_CLIENT_ID',
      defaultValue: '2aGPAheEeSLvfbHOHDIB',
    );
  }
  
  static String get naverClientSecret {
    return const String.fromEnvironment(
      'NAVER_CLIENT_SECRET',
      defaultValue: '1wIsTdaF8Z',
    );
  }
  
  static String get naverClientName {
    return const String.fromEnvironment(
      'NAVER_CLIENT_NAME',
      defaultValue: 'Reward Factory',
    );
  }
  
  // Mobile client credentials for Token Exchange
  static String getMobileClientCredentials() {
    const clientId = 'mobile-client';
    const clientSecret = 'mobile-secret';
    final credentials = '$clientId:$clientSecret';
    return base64Encode(utf8.encode(credentials));
  }
  
  // Edusense SSO configuration
  static String get edusenseAuthUrl {
    if (_environment == Environment.prod) {
      return 'https://auth.edu-sense.shop/oauth2/authorize';
    }
    
    if (!kIsWeb && Platform.isAndroid) {
      // Windows 호스트 서버에 접근
      return 'http://192.168.219.112:8881/oauth2/authorize';
    }
    
    return 'http://localhost:8881/oauth2/authorize';
  }
  
  static String get edusenseClientId => 'reward-client';
}