import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/app_config.dart';
import '../../constants/styles.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../services/kakao_login_service.dart';
import '../../services/token_exchange_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/dio_service.dart';
import '../../models/api_response.dart';
import '../../models/token_dto.dart';

class OAuth2LoginButton extends StatefulWidget {
  final String provider; // 'edusense', 'google', 'kakao'
  final String role;

  const OAuth2LoginButton({
    super.key,
    required this.provider,
    this.role = 'user',
  });

  @override
  State<OAuth2LoginButton> createState() => _OAuth2LoginButtonState();
}

class _OAuth2LoginButtonState extends State<OAuth2LoginButton> {
  String? _codeVerifier;
  String? _state;
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();

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

  Future<void> _handleOAuth2Login() async {
    if (kDebugMode) print('Starting OAuth2 login process for ${widget.provider}');

    // 구글의 경우 네이티브 SDK 사용 (웹 제외)
    if (widget.provider == 'google' && !kIsWeb) {
      try {
        if (kDebugMode) print('Using Google native login');
        
        // 구글 네이티브 로그인 수행
        final result = await TokenExchangeService.authenticateWithGoogle();
        
        if (result != null && mounted) {
          // 서버에서 받은 JWT 토큰으로 로그인 처리
          final tokenDto = TokenDto(
            accessToken: result['access_token'] as String,
            refreshToken: result['refresh_token'] as String?,
          );
          
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.setTokens(
            accessToken: tokenDto.accessToken,
            refreshToken: tokenDto.refreshToken,
          );
          
          if (mounted) {
            final currentLocale = Localizations.localeOf(context).languageCode;
            context.go('/$currentLocale/home');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('구글 로그인에 실패했습니다.')),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) print('Google native login error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('구글 로그인 실패: $e')),
          );
        }
      }
      return;
    }

    // 카카오의 경우 네이티브 SDK 사용 (웹 제외)
    if (widget.provider == 'kakao' && !kIsWeb) {
      try {
        if (kDebugMode) print('Using Kakao native login');
        
        // 카카오 네이티브 로그인 수행
        final result = await TokenExchangeService.authenticateWithKakao();
        
        if (result != null && mounted) {
          // 서버에서 받은 JWT 토큰으로 로그인 처리
          final tokenDto = TokenDto(
            accessToken: result['access_token'] as String,
            refreshToken: result['refresh_token'] as String?,
          );
          
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.setTokens(
            accessToken: tokenDto.accessToken,
            refreshToken: tokenDto.refreshToken,
          );
          
          if (mounted) {
            final currentLocale = Localizations.localeOf(context).languageCode;
            context.go('/$currentLocale/home');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('카카오 로그인에 실패했습니다.')),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) print('Kakao native login error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('카카오 로그인 실패: $e')),
          );
        }
      }
      return;
    }

    // 네이버의 경우 네이티브 SDK 사용 (웹 제외)
    if (widget.provider == 'naver' && !kIsWeb) {
      try {
        if (kDebugMode) print('Using Naver native login');
        
        // 네이버 네이티브 로그인 수행
        final result = await TokenExchangeService.authenticateWithNaver();
        
        if (result != null && mounted) {
          // 서버에서 받은 JWT 토큰으로 로그인 처리
          final tokenDto = TokenDto(
            accessToken: result['access_token'] as String,
            refreshToken: result['refresh_token'] as String?,
          );
          
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.setTokens(
            accessToken: tokenDto.accessToken,
            refreshToken: tokenDto.refreshToken,
          );
          
          if (mounted) {
            final currentLocale = Localizations.localeOf(context).languageCode;
            context.go('/$currentLocale/home');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('네이버 로그인에 실패했습니다.')),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) print('Naver native login error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('네이버 로그인 실패: $e')),
          );
        }
      }
      return;
    }

    // 기존 OAuth2 방식 (웹이거나 다른 provider인 경우)
    try {
      // Generate PKCE parameters
      if (AppConfig.usePKCE) {
        _codeVerifier = _generateCodeVerifier();
        _state = _generateState();
        
        // Store in session storage for web or local storage for mobile
        // This will be retrieved after redirect
        if (kDebugMode) {
          print('Code verifier: $_codeVerifier');
          print('State: $_state');
        }
      }

      // Build authorization URL
      final queryParams = <String, String>{
        'response_type': 'code',
        'client_id': AppConfig.oauth2ClientId,
        'redirect_uri': AppConfig.oauth2RedirectUri,
        'scope': 'openid profile email api.read api.write',
        'state': _state ?? '',
      };

      if (AppConfig.usePKCE && _codeVerifier != null) {
        queryParams['code_challenge'] = _generateCodeChallenge(_codeVerifier!);
        queryParams['code_challenge_method'] = 'S256';
      }

      final authUrl = Uri.parse('${AppConfig.authServerUrl}/oauth2/authorize')
          .replace(queryParameters: queryParams);

      if (kDebugMode) print('Authorization URL: $authUrl');

      // Launch authorization URL
      if (kIsWeb) {
        // Web: redirect in same window
        await launchUrl(
          authUrl,
          webOnlyWindowName: '_self',
        );
      } else {
        // Mobile/Desktop: open in external browser
        await launchUrl(
          authUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (kDebugMode) print('OAuth2 login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  Widget _buildButtonContent() {
    final l10n = AppLocalizations.of(context);
    
    switch (widget.provider) {
      case 'google':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
              padding: const EdgeInsets.all(1),
              child: SvgPicture.asset(
                'assets/images/google.svg',
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.signInWithGoogle,
              style: const TextStyle(
                color: Color(0xFF1F1F1F), // 구글 가이드라인의 어두운 텍스트 색상
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        );
      case 'kakao':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/kakao.svg',
              height: 18,
              width: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '카카오 로그인',
              style: const TextStyle(
                color: Color(0xD9000000), // 85% opacity black
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case 'naver':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF03C75A), // 네이버 녹색
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '네이버 로그인',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case 'edusense':
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/ugot.ico',
              height: 20,
              width: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.signInWithEduSense,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 카카오 버튼 - 디자인 가이드에 따른 스타일 적용
    if (widget.provider == 'kakao') {
      return Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE500), // 카카오 yellow
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: _handleOAuth2Login,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildButtonContent(),
        ),
      );
    }

    // 구글 버튼 - 구글 브랜딩 가이드라인에 따른 스타일 적용
    if (widget.provider == 'google') {
      return Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white, // 밝은 테마 - 흰색 배경
          border: Border.all(color: const Color(0xFFDADCE0)), // 구글 가이드라인 보더 색상
          borderRadius: BorderRadius.circular(4), // 구글 권장 border radius
        ),
        child: TextButton(
          onPressed: _handleOAuth2Login,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: _buildButtonContent(),
        ),
      );
    }

    // 네이버 버튼 - 네이버 브랜딩 가이드라인에 따른 스타일 적용
    if (widget.provider == 'naver') {
      return Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF03C75A), // 네이버 녹색
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: _handleOAuth2Login,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildButtonContent(),
        ),
      );
    }

    // 기본 OAuth2 버튼 스타일 (EduSense 등)
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: _handleOAuth2Login,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }
}