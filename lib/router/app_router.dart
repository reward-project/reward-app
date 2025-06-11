import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_page_modern.dart';
// import '../screens/auth/signin_page.dart'; // 제거됨 - DioService 사용
// import '../screens/auth/auth_callback_page.dart'; // 제거됨 - DioService 사용
import '../screens/auth/oauth2_callback_page.dart';
import '../screens/home/home_page_modern.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';
import '../screens/mypage/mypage_screen_modern.dart';
import '../screens/layout/modern_home_layout.dart';
import '../screens/cash_history/cash_history_screen_modern.dart';
import '../screens/withdrawal/withdrawal_request_screen.dart';
// import '../screens/profile/profile_edit_screen.dart'; // 제거됨 - DioService 사용
// import '../screens/mission/mission_list_screen.dart'; // 제거됨 - DioService 사용
import '../screens/mission/missions_screen_modern.dart';
import '../screens/mission/mission_detail_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;
    
    // 초기화가 완료되지 않은 경우 null을 반환하여 현재 페이지 유지
    if (!authProvider.isInitialized) {
      // 비동기적으로 초기화 수행 (별도의 Future로)
      Future.microtask(() async {
        await authProvider.initializeAuth();
      });
      return null; // 초기화 중에는 리다이렉트하지 않음
    }
    // 현재 경로에서 해시(#)와 쿼리 파라미터 제거
    final path = state.uri.path.replaceAll('#', '').split('?')[0]; // 쿼리 파라미터 제거

    if (kDebugMode) {
      print('🔄 Router Redirect:');
      print('Current path: $path');
      print('Full URI: ${state.uri}');
      print('isAuthenticated: ${authProvider.isAuthenticated}');
      print('Locale: $locale');
    }

    // callback 페이지인 경우 locale을 추가하여 리다이렉트
    if (path == '/auth/callback') {
      return '/$locale/auth/callback';
    }
    
    // OAuth2 callback 페이지
    if (path == '/oauth2/redirect') {
      return '/$locale/oauth2/redirect';
    }

    // 인증이 필요하지 않은 경로들
    final publicPaths = [
      '/$locale/login',
      '/$locale/login/email',
      '/$locale/signin',
      '/auth/callback', // locale 없는 버전도 추가
      '/$locale/auth/callback',
      '/oauth2/redirect',
      '/$locale/oauth2/redirect',
    ];

    // 루트 경로나 locale만 있는 경로 처리
    if (path == '/' || path == '/$locale') {
      final redirectPath =
          authProvider.isAuthenticated ? '/$locale/home' : '/$locale/login';
      if (kDebugMode) print('⏩ Root path redirect: $redirectPath');
      return redirectPath;
    }

    // 나머지 리다이렉트 로직
    if (!authProvider.isAuthenticated) {
      if (!publicPaths.contains(path)) {
        return '/$locale/login';
      }
    } else {
      if (publicPaths.contains(path) && !path.contains('/auth/callback')) {
        return '/$locale/home';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
        final locale = Localizations.localeOf(context).languageCode;
        return authProvider.isAuthenticated ? '/$locale/home' : '/$locale/login';
      },
    ),
    GoRoute(
      path: '/:locale',
      redirect: (context, state) {
        final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
        final locale = state.pathParameters['locale']!;
        return authProvider.isAuthenticated ? '/$locale/home' : '/$locale/login';
      },
    ),
    // locale이 없는 callback 경로도 추가
    GoRoute(
      path: '/auth/callback',
      redirect: (context, state) {
        final locale = Localizations.localeOf(context).languageCode;
        return '/$locale/auth/callback';
      },
    ),
    // OAuth2 redirect 경로
    GoRoute(
      path: '/oauth2/redirect',
      redirect: (context, state) {
        final locale = Localizations.localeOf(context).languageCode;
        return '/$locale/oauth2/redirect';
      },
    ),
    GoRoute(
      path: '/:locale/login',
      builder: (context, state) => LoginPageModern(
        locale: Locale(state.pathParameters['locale']!),
      ),
    ),
    GoRoute(
      path: '/:locale/login/email',
      builder: (context, state) => LoginPageModern(
        locale: Locale(state.pathParameters['locale']!),
      ),
    ),
    // GoRoute(
    //   path: '/:locale/signin',
    //   builder: (context, state) => const SignInPage(),
    // ),
    GoRoute(
      path: '/:locale/home',
      builder: (context, state) => ModernHomeLayout(
        child: HomePageModern(locale: Locale(state.pathParameters['locale']!)),
      ),
    ),
    // GoRoute(
    //   path: '/:locale/auth/callback',
    //   builder: (context, state) => const AuthCallbackPage(),
    // ),
    GoRoute(
      path: '/:locale/oauth2/redirect',
      builder: (context, state) => const OAuth2CallbackPage(),
    ),
    GoRoute(
      path: '/:locale/mypage',
      builder: (context, state) => const ModernHomeLayout(
        child: MyPageScreenModern(),
      ),
    ),
    GoRoute(
      path: '/:locale/cash-history',
      builder: (context, state) => const ModernHomeLayout(
        child: CashHistoryScreenModern(),
      ),
    ),
    GoRoute(
      path: '/:locale/withdrawal-request',
      builder: (context, state) => const ModernHomeLayout(
        child: WithdrawalRequestScreen(),
      ),
    ),
    // GoRoute(
    //   path: '/:locale/profile-edit',
    //   builder: (context, state) => const ModernHomeLayout(
    //     child: ProfileEditScreen(),
    //   ),
    // ),
    // GoRoute(
    //   path: '/:locale/mission-list',
    //   builder: (context, state) => const ModernHomeLayout(
    //     child: MissionListScreen(),
    //   ),
    // ),
    GoRoute(
      path: '/:locale/missions',
      builder: (context, state) => const ModernHomeLayout(
        child: MissionsScreenModern(),
      ),
    ),
    GoRoute(
      path: '/:locale/mission/:missionId',
      builder: (context, state) => MissionDetailScreen(
        missionId: state.pathParameters['missionId']!,
      ),
    ),
    // GoRoute(
    //   path: '/:locale/settlement',
    //   builder: (context, state) => const ModernHomeLayout(
    //     child: SettlementDashboardScreen(),
    //   ),
    // ),
    // GoRoute(
    //   path: '/:locale/settlement/history',
    //   builder: (context, state) => const ModernHomeLayout(
    //     child: SettlementHistoryScreen(),
    //   ),
    // ),
    // GoRoute(
    //   path: '/:locale/settlement/status',
    //   builder: (context, state) {
    //     final settlementId = state.uri.queryParameters['id'];
    //     return ModernHomeLayout(
    //       child: SettlementStatusScreen(
    //         settlementId: settlementId != null ? int.tryParse(settlementId) : null,
    //       ),
    //     );
    //   },
    // ),
  ],
);
