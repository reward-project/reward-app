import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';
import 'package:reward_common/reward_common.dart';

class LoginPageModern extends StatefulWidget {
  final Locale? locale;

  const LoginPageModern({super.key, this.locale});

  @override
  State<LoginPageModern> createState() => _LoginPageModernState();
}

class _LoginPageModernState extends State<LoginPageModern> {
  Future<void> _handleLoginSuccess(TokenDto tokenDto) async {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    
    await authProvider.setTokens(
      accessToken: tokenDto.accessToken,
      refreshToken: tokenDto.refreshToken,
    );
    
    if (mounted) {
      final currentLocale = widget.locale?.languageCode ?? 'ko';
      context.go('/$currentLocale/home');
    }
  }

  void _handleLoginCancel() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonLoginPage(
      appTitle: 'Reward App',
      subtitle: '포인트를 모으고 리워드를 받아보세요',
      onLoginSuccess: _handleLoginSuccess,
      onLoginCancel: _handleLoginCancel,
      showGoogleLogin: true,
      showKakaoLogin: true,
      showNaverLogin: true,
      showEdusenseLogin: false,
      headerWidget: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            // 앱 로고
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: const Icon(
                Icons.card_giftcard,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reward App',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '포인트를 모으고 리워드를 받아보세요',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}