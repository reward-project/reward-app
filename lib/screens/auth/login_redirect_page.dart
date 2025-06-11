import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LoginRedirectPage extends StatefulWidget {
  const LoginRedirectPage({super.key});

  @override
  State<LoginRedirectPage> createState() => _LoginRedirectPageState();
}

class _LoginRedirectPageState extends State<LoginRedirectPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 자동으로 AuthServer로 리다이렉트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToAuthServer();
    });
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

  Future<void> _redirectToAuthServer() async {
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
      if (kDebugMode) print('Redirect error: $e');
      // 에러 발생 시 폴백 UI 표시
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Redirecting to login...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 48),
            // 폴백: 자동 리다이렉트 실패 시 수동 버튼 제공
            TextButton(
              onPressed: _redirectToAuthServer,
              child: const Text('Click here if not redirected'),
            ),
          ],
        ),
      ),
    );
  }
}