import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:responsive_framework/responsive_framework.dart';
// import 'package:naver_login_sdk/naver_login_sdk.dart'; // API 문제로 임시 제거
import 'router/app_router.dart';
import 'providers/locale_provider.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'services/dio_service.dart';
import 'services/naver_login_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'theme/app_theme.dart';

// 웹 전용 import를 조건부로 처리

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  AppConfig.initialize(env == 'prod' ? Environment.prod : Environment.dev);

  // 카카오 SDK 초기화
  if (!kIsWeb) {
    KakaoSdk.init(
      nativeAppKey: AppConfig.kakaoNativeAppKey,
    );
    if (kDebugMode) {
      print('카카오 SDK 초기화 완료');
    }
  }
  
  // 네이버 SDK 초기화 (API 문제로 임시 제거)
  // if (!kIsWeb) {
  //   await NaverLoginSDK.initialize(
  //     clientId: AppConfig.naverClientId,
  //     clientName: AppConfig.naverClientName,
  //     clientSecret: AppConfig.naverClientSecret,
  //   );
  //   if (kDebugMode) {
  //     print('네이버 SDK 초기화 완료');
  //   }
  // }
  await NaverLoginService.initializeNaverSDK(); // 웹뷰 기반 초기화

  if (kDebugMode) {
    print('\n=== App Configuration ===');
    print('🌍 Environment: ${env == 'prod' ? 'Production' : 'Development'}');
    print('🌐 Backend URL: ${AppConfig.apiBaseUrl}${AppConfig.apiPath}');
    print('========================\n');
  }

  final navigatorKey = GlobalKey<NavigatorState>();
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context)..initializeAuth(),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MyApp(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
    ),
  );

  // 로컬 서버 시작
  if (!kIsWeb) {
    startLocalServer(navigatorKey);
  }
}

Future<void> precacheFonts() async {
  final fontLoader = FontLoader('NotoSansKR');
  fontLoader.addFont(rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf'));
  fontLoader.addFont(rootBundle.load('assets/fonts/NotoSansKR-Medium.ttf'));
  fontLoader.addFont(rootBundle.load('assets/fonts/NotoSansKR-Bold.ttf'));
  await fontLoader.load();
}

void startLocalServer(GlobalKey<NavigatorState> navigatorKey) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8765);
  print('Listening on localhost:${server.port}');

  await for (HttpRequest request in server) {
    final uri = request.uri;
    if (uri.path == '/auth/callback') {
      final accessToken = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken'];
      final locale = uri.queryParameters['locale'];
      if (accessToken != null && refreshToken != null) {
        final context = navigatorKey.currentContext!;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        print('Access Token: $accessToken');
        print('Refresh Token: $refreshToken');

        // /home으로 리다이렉트

        // router.go를 사용하여 홈 화면으로 이동
        router.go('/$locale/home');
      }

      // 사용자 친화적인 HTML 응답
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('''
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Authentication Complete</title>
            <style>
              body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
              h1 { color: #4CAF50; }
              p { font-size: 18px; }
            </style>
          </head>
          <body>
            <h1>Authentication Complete</h1>
            <p>You can close this window and return to the app.</p>
          </body>
          </html>
        ''')
        ..close();
    }
  }
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            return MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          routerConfig: router,
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('ko', ''),
            Locale('en', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            DioService.init(context);
            return ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            );
          },
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          themeMode: ThemeMode.system,
          title: '리워드 팩토리', // 기본 타이틀
          onGenerateTitle: (context) {
            // 현재 로케일에 따라 타이틀 반환
            return AppLocalizations.of(context).appTitle;
          },
        );
          },
        );
      },
    );
  }
}

// 커스텀 NoTransitionsBuilder 클래스
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
