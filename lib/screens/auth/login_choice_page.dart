import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../constants/styles.dart';
import 'package:reward_common/widgets/common/language_dropdown.dart';
import 'package:reward_common/widgets/social_login_button.dart';
import 'package:reward_common/utils/responsive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/google_login_service.dart';
import '../../services/kakao_login_service.dart';
import '../../services/naver_login_service.dart';
import 'package:provider/provider.dart';
import 'package:reward_common/providers/auth_provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LoginChoicePage extends StatefulWidget {
  final Locale? locale;

  const LoginChoicePage({super.key, this.locale});

  @override
  State<LoginChoicePage> createState() => _LoginChoicePageState();
}

class _LoginChoicePageState extends State<LoginChoicePage> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = widget.locale?.languageCode ?? Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: SafeArea(
        child: _buildResponsiveLayout(context, l10n, locale),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, AppLocalizations l10n, String locale) {
    if (isDesktop(context)) {
      return _buildDesktopLayout(context, l10n, locale);
    } else if (isTablet(context)) {
      return _buildTabletLayout(context, l10n, locale);
    } else {
      return _buildMobileLayout(context, l10n, locale);
    }
  }

  Widget _buildMobileLayout(BuildContext context, AppLocalizations l10n, String locale) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildHeader(context, l10n),
          Expanded(
            child: _buildLoginContent(context, l10n, locale),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, AppLocalizations l10n, String locale) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: _buildBrandingSection(context, l10n),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              children: [
                _buildHeader(context, l10n),
                Expanded(
                  child: _buildLoginContent(context, l10n, locale),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppLocalizations l10n, String locale) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: _buildBrandingSection(context, l10n),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(context, l10n),
                  const SizedBox(height: 32),
                  _buildLoginContent(context, l10n, locale),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const LanguageDropdown(),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          l10n.selectLoginMethod,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.choosePreferredLoginMethod,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBrandingSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.rocket_launch,
            size: 80,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.welcomeToReward,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.rewardAppDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginContent(BuildContext context, AppLocalizations l10n, String locale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNativeLoginSection(context, l10n, locale),
        const SizedBox(height: 32),
        _buildDivider(context, l10n),
        const SizedBox(height: 32),
        _buildSSOLoginSection(context, l10n, locale),
        // 이메일/비밀번호 로그인과 회원가입 링크 제거 - UGOT에서 모든 기능 제공
      ],
    );
  }

  Widget _buildNativeLoginSection(BuildContext context, AppLocalizations l10n, String locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.nativeLogin,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.nativeLoginDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SocialLoginButton(
          type: SocialLoginType.google,
          onPressed: () => _handleOAuth2Login(context, 'google'),
          text: l10n.loginWithGoogle,
        ),
        const SizedBox(height: 12),
        // 모바일에서만 카카오, 네이버 네이티브 로그인 표시
        if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                        defaultTargetPlatform == TargetPlatform.iOS)) ...[
          SocialLoginButton(
            type: SocialLoginType.kakao,
            onPressed: () => _handleOAuth2Login(context, 'kakao'),
            text: l10n.loginWithKakao,
          ),
          const SizedBox(height: 12),
          SocialLoginButton(
            type: SocialLoginType.naver,
            onPressed: () => _handleOAuth2Login(context, 'naver'),
            text: l10n.loginWithNaver,
          ),
        ],
      ],
    );
  }

  Widget _buildDivider(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.or,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSSOLoginSection(BuildContext context, AppLocalizations l10n, String locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ssoLogin,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.ssoLoginDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // 모바일에서는 Google SSO 버튼 숨김 (네이티브 로그인 사용)
        if (!(!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                          defaultTargetPlatform == TargetPlatform.iOS)))
          SocialLoginButton(
            type: SocialLoginType.google,
            onPressed: () => _handleOAuth2Login(context, 'google'),
            text: l10n.loginWithGoogle,
          ),
        if (!(!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                          defaultTargetPlatform == TargetPlatform.iOS)))
          const SizedBox(height: 12),
        SocialLoginButton(
          type: SocialLoginType.edusense,
          onPressed: () => _handleOAuth2Login(context, 'edusense'),
          text: l10n.loginWithEdusense,
        ),
      ],
    );
  }

  Widget _buildAlternativeLoginSection(BuildContext context, AppLocalizations l10n, String locale) {
    // 이메일/비밀번호 로그인과 회원가입 링크 제거 - UGOT에서 모든 기능 제공
    return const SizedBox.shrink();
  }

  // OAuth2 로그인 처리 메서드
  Future<void> _handleOAuth2Login(BuildContext context, String provider) async {
    if (kDebugMode) print('Starting OAuth2 login process for $provider');

    // 구글의 경우 네이티브 SDK 사용 (웹 제외)
    if (provider == 'google' && !kIsWeb) {
      await _handleGoogleLogin();
      return;
    }

    // 카카오의 경우 네이티브 SDK 사용 (웹 제외)
    if (provider == 'kakao' && !kIsWeb) {
      await _handleKakaoLogin();
      return;
    }

    // 네이버의 경우 네이티브 SDK 사용 (웹 제외)
    if (provider == 'naver' && !kIsWeb) {
      await _handleNaverLogin();
      return;
    }

    // 기존 OAuth2 방식 (웹이거나 다른 provider인 경우)
    try {
      // Generate PKCE parameters
      String? codeVerifier;
      String? state;
      
      if (AppConfig.usePKCE) {
        codeVerifier = _generateCodeVerifier();
        state = _generateState();
        
        // Store PKCE parameters for later use in callback
        await AuthService.storePKCEParameters(codeVerifier, state);
        
        if (kDebugMode) {
          print('Code verifier: $codeVerifier');
          print('State: $state');
        }
      }

      // Build authorization URL
      final queryParams = <String, String>{
        'response_type': 'code',
        'client_id': AppConfig.oauth2ClientId,
        'redirect_uri': AppConfig.oauth2RedirectUri,
        'scope': 'openid profile email api.read api.write',
        'state': state ?? '',
      };

      if (provider != 'edusense') {
        queryParams['provider'] = provider;
      }

      if (AppConfig.usePKCE && codeVerifier != null) {
        queryParams['code_challenge'] = _generateCodeChallenge(codeVerifier);
        queryParams['code_challenge_method'] = 'S256';
      }

      final authUrl = Uri.parse('${AppConfig.authServerUrl}/oauth2/authorize')
          .replace(queryParameters: queryParams);

      if (kDebugMode) print('Redirecting to: $authUrl');

      // Launch authorization URL
      await launchUrl(
        authUrl,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );
    } catch (e) {
      if (kDebugMode) print('OAuth2 error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    }
  }

  /// 구글 로그인 처리
  Future<void> _handleGoogleLogin() async {
    try {
      if (kDebugMode) print('🔵 구글 로그인 시작');
      
      final tokenDto = await GoogleLoginService.signIn();
      
      if (tokenDto != null && mounted) {
        if (kDebugMode) print('✅ 구글 로그인 성공');
        
        final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
        await authProvider.setTokens(
          accessToken: tokenDto.accessToken,
          refreshToken: tokenDto.refreshToken,
        );
        
        if (mounted) {
          final currentLocale = Localizations.localeOf(context).languageCode;
          context.go('/$currentLocale/home');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구글 로그인에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ 구글 로그인 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구글 로그인 실패: $e')),
        );
      }
    }
  }

  /// 카카오 로그인 처리
  Future<void> _handleKakaoLogin() async {
    try {
      if (kDebugMode) print('🟡 카카오 로그인 시작');
      
      final tokenDto = await KakaoLoginService.signIn();
      
      if (tokenDto != null && mounted) {
        if (kDebugMode) print('✅ 카카오 로그인 성공');
        
        final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
        await authProvider.setTokens(
          accessToken: tokenDto.accessToken,
          refreshToken: tokenDto.refreshToken,
        );
        
        if (mounted) {
          final currentLocale = Localizations.localeOf(context).languageCode;
          context.go('/$currentLocale/home');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오 로그인에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ 카카오 로그인 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카카오 로그인 실패: $e')),
        );
      }
    }
  }

  /// 네이버 로그인 처리
  Future<void> _handleNaverLogin() async {
    try {
      if (kDebugMode) print('🟢 네이버 로그인 시작');
      
      final tokenDto = await NaverLoginService.signIn();
      
      if (tokenDto != null && mounted) {
        if (kDebugMode) print('✅ 네이버 로그인 성공');
        
        final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
        await authProvider.setTokens(
          accessToken: tokenDto.accessToken,
          refreshToken: tokenDto.refreshToken,
        );
        
        if (mounted) {
          final currentLocale = Localizations.localeOf(context).languageCode;
          context.go('/$currentLocale/home');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네이버 로그인에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ 네이버 로그인 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네이버 로그인 실패: $e')),
        );
      }
    }
  }

  // PKCE code verifier generator
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // PKCE code challenge generator
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // Generate random state
  String _generateState() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }
}