import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/api_response.dart';
import '../../widgets/modern_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../services/dio_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import '../../models/token_dto.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../utils/responsive.dart';
// Social login services are now handled through AuthProvider

class LoginPageModern extends StatefulWidget {
  final Locale? locale;

  const LoginPageModern({super.key, this.locale});

  @override
  State<LoginPageModern> createState() => _LoginPageModernState();
}

class _LoginPageModernState extends State<LoginPageModern> with TickerProviderStateMixin {
  bool _isLoading = false;
  late Dio _dio;
  late AnimationController _animationController;
  late AnimationController _logoAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dio = DioService.instance;
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = false;
      
      switch (provider) {
        case 'google':
          success = await authProvider.loginWithGoogle();
          break;
        case 'kakao':
          success = await authProvider.loginWithKakao();
          break;
        case 'naver':
          success = await authProvider.loginWithNaver();
          break;
      }
      
      if (success && mounted) {
        final currentLocale = widget.locale?.languageCode ?? 'ko';
        if (mounted) {
          context.go('/$currentLocale/home');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider} 로그인에 실패했습니다'),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('소셜 로그인에 실패했습니다: ${e.toString()}'),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = ResponsiveUtil.isTablet(context);
    final isDesktop = ResponsiveUtil.isDesktop(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.primaryContainer.withOpacity(0.1),
              context.colorScheme.secondaryContainer.withOpacity(0.05),
              context.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? size.width * 0.3 : (isTablet ? 48 : 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo and Title
                  _buildLogoSection(),
                  
                  const SizedBox(height: 60),
                  
                  // Social Login Buttons - 디자인 가이드에 맞게 수정
                  _buildSocialLoginButtons(),
                  
                  const SizedBox(height: 32),
                  
                  // Divider
                  _buildDivider(),
                  
                  const SizedBox(height: 32),
                  
                  // UGOT SSO Login
                  _buildUgotLogin(),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _logoAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_logoAnimationController.value * 0.1),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colorScheme.primary,
                      context.colorScheme.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.card_giftcard,
                  size: 60,
                  color: context.colorScheme.onPrimary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          '리워드 팩토리',
          style: context.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.onSurface,
          ),
        ).animate()
          .fadeIn(delay: 200.ms, duration: 800.ms)
          .slideY(begin: 0.3, end: 0),
        const SizedBox(height: 12),
        Text(
          '로그인하여 리워드를 받아보세요',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ).animate()
          .fadeIn(delay: 400.ms, duration: 800.ms)
          .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320), // 버튼 최대 너비 제한
      child: Column(
        children: [
          // Google Sign-in Button - Google 디자인 가이드 준수
          _buildGoogleSignInButton(),
          
          const SizedBox(height: 12),
          
          // Kakao Login Button - Kakao 디자인 가이드 준수
          _buildKakaoLoginButton(),
          
          const SizedBox(height: 12),
          
          // Naver Login Button - Naver 디자인 가이드 준수
          _buildNaverLoginButton(),
        ],
      ),
    );
  }

  // Google 공식 디자인 가이드에 따른 버튼
  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: InkWell(
        onTap: _isLoading ? null : () => _handleSocialLogin('google'),
        borderRadius: BorderRadius.circular(4), // Google 가이드: 4px radius
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFDADCE0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google "G" 로고
                SvgPicture.asset(
                  'assets/images/google.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 24),
                const Text(
                  'Google로 로그인',
                  style: TextStyle(
                    color: Color(0xFF3C4043),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 600.ms, duration: 800.ms)
      .slideY(begin: 0.1, end: 0);
  }

  // Kakao 공식 디자인 가이드에 따른 버튼
  Widget _buildKakaoLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: InkWell(
        onTap: _isLoading ? null : () => _handleSocialLogin('kakao'),
        borderRadius: BorderRadius.circular(12), // Kakao 가이드: 12px radius
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEE500), // Kakao Yellow
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Kakao 말풍선 심볼
                SvgPicture.asset(
                  'assets/images/kakao.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '카카오 로그인',
                  style: TextStyle(
                    color: const Color(0xFF000000).withOpacity(0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 700.ms, duration: 800.ms)
      .slideY(begin: 0.1, end: 0);
  }

  // Naver 공식 디자인 가이드에 따른 버튼
  Widget _buildNaverLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: InkWell(
        onTap: _isLoading ? null : () => _handleSocialLogin('naver'),
        borderRadius: BorderRadius.circular(6), // Naver 스타일
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF03C75A), // Naver Green
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Naver "N" 로고
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  child: const Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.0, // 줄 높이를 1로 설정하여 정확히 중앙 정렬
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '네이버 로그인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: 800.ms, duration: 800.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: context.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '또는',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: context.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ],
    ).animate()
      .fadeIn(delay: 900.ms, duration: 800.ms);
  }

  Widget _buildUgotLogin() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _handleUgotLogin(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/ugot.ico',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '유갓 통합 로그인',
              style: TextStyle(
                color: context.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: 1000.ms, duration: 800.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Future<void> _handleUgotLogin() async {
    final currentLocale = widget.locale?.languageCode ?? 'ko';
    final redirectUri = Uri.encodeComponent(
      kIsWeb
          ? '${Uri.base.origin}/$currentLocale/auth/callback'
          : 'http://localhost:8765/auth/callback',
    );
    
    final authUrl = '${AppConfig.edusenseAuthUrl}'
        '?response_type=code'
        '&client_id=${AppConfig.edusenseClientId}'
        '&redirect_uri=$redirectUri'
        '&scope=openid profile email'
        '&state=$currentLocale';
    
    if (await canLaunchUrl(Uri.parse(authUrl))) {
      await launchUrl(Uri.parse(authUrl));
    }
  }
}