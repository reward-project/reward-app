import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:responsive_framework/responsive_framework.dart' hide ResponsiveBreakpoints;
import 'package:responsive_framework/responsive_framework.dart' as rf;
// import 'package:naver_login_sdk/naver_login_sdk.dart'; // API 문제로 임시 제거
import 'router/app_router.dart';
import 'package:reward_common/config/app_config.dart' as common_config;
import 'providers/auth_provider_extended.dart';
import 'providers/api_provider.dart';
// import 'services/dio_service.dart'; // 제거됨 - reward_common 사용
import 'services/naver_login_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:reward_common/reward_common.dart';

// 웹 전용 import를 조건부로 처리

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  common_config.AppConfig.initialize(
    env: env == 'prod' ? common_config.Environment.prod : common_config.Environment.dev,
    appType: common_config.AppType.app,
  );
  
  final appConfig = common_config.AppConfig.instance;

  // reward_common의 AuthConfig 초기화
  AuthConfig.initialize(
    authServerUrl: appConfig.authServerUrl,
    googleWebClientId: appConfig.googleClientId,
    kakaoNativeAppKey: appConfig.kakaoNativeAppKey,
    naverClientId: appConfig.naverClientId,
    naverClientSecret: appConfig.naverClientSecret,
  );

  // 카카오 SDK 초기화
  if (!kIsWeb) {
    KakaoSdk.init(
      nativeAppKey: appConfig.kakaoNativeAppKey,
    );
    if (kDebugMode) {
      print('🎯 Kakao SDK initialized with key: ${appConfig.kakaoNativeAppKey}');
    }
  }

  // 네이버 로그인 SDK 초기화 (임시 비활성화)
  // try {
  //   await NaverLoginSDK.initialize(
  //     clientId: appConfig.naverClientId,
  //     clientSecret: appConfig.naverClientSecret,
  //     clientName: '리워드팩토리',
  //   );
  // } catch (e) {
  //   if (kDebugMode) {
  //     print('❌ NaverLoginSDK 초기화 실패: $e');
  //   }
  // }

  if (kDebugMode) {
    print('🌐 Backend URL: ${appConfig.apiBaseUrl}${appConfig.apiPath}');
    print('🔐 Auth Server URL: ${appConfig.authServerUrl}');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  MyApp({
    super.key,
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        scaffoldMessengerKey = scaffoldMessengerKey ?? GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => AuthProviderExtended(
                navigatorKey: navigatorKey,
                scaffoldMessengerKey: scaffoldMessengerKey,
              ),
            ),
            ChangeNotifierProvider(
              create: (context) => ApiProvider(),
            ),
          ],
          child: Consumer<AuthProviderExtended>(
            builder: (context, authProvider, child) {
              final themeMode = authProvider.themeMode;
              
              return MaterialApp.router(
                title: 'Reward Factory',
                navigatorKey: navigatorKey,
                scaffoldMessengerKey: scaffoldMessengerKey,
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('ko', 'KR'),
                  Locale('en', 'US'),
                ],
                themeMode: themeMode,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: lightColorScheme,
                  brightness: Brightness.light,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: darkColorScheme,
                  brightness: Brightness.dark,
                ),
                routerConfig: AppRouter(authProvider).router,
                builder: (context, child) => ResponsiveBreakpoints.builder(
                  child: child!,
                  breakpoints: [
                    const rf.Breakpoint(start: 0, end: 450, name: MOBILE),
                    const rf.Breakpoint(start: 451, end: 800, name: TABLET),
                    const rf.Breakpoint(start: 801, end: 1920, name: DESKTOP),
                    const rf.Breakpoint(start: 1921, end: double.infinity, name: '4K'),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}