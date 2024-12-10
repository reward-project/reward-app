import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/signin_page.dart';
import '../screens/auth/auth_callback_page.dart';
import '../screens/home/home_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/mypage/mypage_screen.dart';
import '../screens/layout/home_layout.dart';
import '../screens/cash_history/cash_history_screen.dart';
import '../screens/withdrawal/withdrawal_request_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../screens/mission/mission_list_screen.dart';
import '../screens/mission/missions_screen.dart';
import '../screens/mission/mission_detail_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;
    // 초기화가 완료될 때까지 대기
    if (!authProvider.isInitialized) {
      await authProvider.initializeAuth();
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

    // 인증이 필요하지 않은 경로들
    final publicPaths = [
      '/$locale/login',
      '/$locale/signin',
      '/auth/callback', // locale 없는 버전도 추가
      '/$locale/auth/callback',
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
        final locale = Localizations.localeOf(context).languageCode;
        return '/$locale/home';
      },
    ),
    GoRoute(
      path: '/:locale',
      redirect: (context, state) {
        final locale = state.pathParameters['locale']!;
        return '/$locale/home';
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
    GoRoute(
      path: '/:locale/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/:locale/signin',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/:locale/home',
      builder: (context, state) => HomeLayout(
        child: HomePage(locale: Locale(state.pathParameters['locale']!)),
      ),
    ),
    GoRoute(
      path: '/:locale/auth/callback',
      builder: (context, state) => const AuthCallbackPage(),
    ),
    GoRoute(
      path: '/:locale/mypage',
      builder: (context, state) => const HomeLayout(
        child: MyPageScreen(),
      ),
    ),
    GoRoute(
      path: '/:locale/cash-history',
      builder: (context, state) => const HomeLayout(
        child: CashHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/:locale/withdrawal-request',
      builder: (context, state) => const HomeLayout(
        child: WithdrawalRequestScreen(),
      ),
    ),
    GoRoute(
      path: '/:locale/profile-edit',
      builder: (context, state) => const HomeLayout(
        child: ProfileEditScreen(),
      ),
    ),
    GoRoute(
      path: '/:locale/mission-list',
      builder: (context, state) => const HomeLayout(
        child: MissionListScreen(),
      ),
    ),
    GoRoute(
      path: '/:locale/missions',
      builder: (context, state) => const HomeLayout(
        child: MissionsScreen(),
      ),
    ),
    GoRoute(
      path: '/:locale/mission/:rewardNo',
      builder: (context, state) => HomeLayout(
        child: MissionDetailScreen(
          rewardNo: int.parse(state.pathParameters['rewardNo']!),
        ),
      ),
    ),
  ],
);
