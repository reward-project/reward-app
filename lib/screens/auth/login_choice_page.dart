import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../constants/styles.dart';
import '../../widgets/common/language_dropdown.dart';
import '../../widgets/auth/oauth2_login_button.dart';
import '../../utils/responsive.dart';

class LoginChoicePage extends StatelessWidget {
  final Locale? locale;

  const LoginChoicePage({super.key, this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = this.locale?.languageCode ?? Localizations.localeOf(context).languageCode;

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
        const OAuth2LoginButton(provider: 'google'),
        const SizedBox(height: 12),
        // 모바일에서만 카카오, 네이버 네이티브 로그인 표시
        if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                        defaultTargetPlatform == TargetPlatform.iOS)) ...[
          const OAuth2LoginButton(provider: 'kakao'),
          const SizedBox(height: 12),
          const OAuth2LoginButton(provider: 'naver'),
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
          const OAuth2LoginButton(provider: 'google'),
        if (!(!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                          defaultTargetPlatform == TargetPlatform.iOS)))
          const SizedBox(height: 12),
        const OAuth2LoginButton(provider: 'edusense'),
      ],
    );
  }

  Widget _buildAlternativeLoginSection(BuildContext context, AppLocalizations l10n, String locale) {
    // 이메일/비밀번호 로그인과 회원가입 링크 제거 - UGOT에서 모든 기능 제공
    return const SizedBox.shrink();
  }
}