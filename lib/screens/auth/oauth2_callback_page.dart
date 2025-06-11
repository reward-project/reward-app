import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';
// import '../../services/dio_service.dart'; // 제거됨 - reward_common 사용
// import '../../services/auth_service.dart'; // 제거됨
import '../../config/app_config.dart';
// import '../../models/api_response.dart'; // 제거됨
import 'package:reward_common/reward_common.dart';
import '../../providers/api_provider.dart';
import 'package:reward_common/models/token_dto.dart';

class OAuth2CallbackPage extends StatefulWidget {
  const OAuth2CallbackPage({super.key});

  @override
  State<OAuth2CallbackPage> createState() => _OAuth2CallbackPageState();
}

class _OAuth2CallbackPageState extends State<OAuth2CallbackPage> {
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Get query parameters
      final uri = Uri.base;
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      if (kDebugMode) {
        print('OAuth2 callback received:');
        print('Code: $code');
        print('State: $state');
        print('Error: $error');
      }

      if (error != null) {
        throw Exception('OAuth2 error: $error');
      }

      if (code == null) {
        throw Exception('No authorization code received');
      }

      // Get stored PKCE parameters if using PKCE
      Map<String, String> requestData = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': AppConfig.oauth2RedirectUri,
        'client_id': AppConfig.oauth2ClientId,
      };

      if (AppConfig.usePKCE) {
        // final pkceParams = await AuthService.getPKCEParameters();
        final pkceParams = null; // TODO: PKCE 구현 필요
        final codeVerifier = pkceParams?['codeVerifier'];
        final storedState = pkceParams?['state'];
        
        if (codeVerifier != null) {
          requestData['code_verifier'] = codeVerifier;
        }
        
        // Verify state parameter
        if (storedState != null && storedState != state) {
          throw Exception('Invalid state parameter');
        }
        
        // Clear PKCE parameters after use
        // await AuthService.clearPKCEParameters(); // TODO: PKCE 구현 필요
      }

      // Exchange code for tokens using proxy
      final apiResponse = await context.apiService.post<Map<String, dynamic>>(
        '${AppConfig.authServerUrl}/api/proxy/token',
        data: requestData,
        // TODO: FormUrlEncoded 지원 필요
      );

      final tokenData = apiResponse.data;
      
      if (kDebugMode) {
        print('Token response: $tokenData');
      }

      // Extract tokens
      final accessToken = tokenData?['access_token'];
      final refreshToken = tokenData?['refresh_token'];
      
      if (accessToken == null) {
        throw Exception('No access token received');
      }

      // Store tokens in AuthProvider
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      await authProvider.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Fetch user information from authserver
      try {
        // TODO: ApiService로 교체 필요
        // final userResponse = await context.apiService.get('/api/user/me');
        // 임시로 주석처리
        final userResponse = null; // await dio.get('/api/user/me');
        
        if (userResponse != null && userResponse.statusCode == 200) {
          final userData = userResponse.data;
          
          if (kDebugMode) {
            print('User data from authserver: $userData');
          }
          
          // Update user information in AuthProvider
          // TODO: reward_common의 AuthProvider에서 사용자 정보 업데이트 방법 구현 필요
          // await authProvider.updateUserInfo(
          //   userId: userData['id']?.toString() ?? '',
          //   userEmail: userData['email'] ?? '',
          //   userName: userData['name'] ?? userData['username'] ?? 'User',
          //   userType: 'customer',
          // );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to fetch user info: $e');
        }
        // Continue anyway - we have tokens
      }

      // Redirect to home
      if (mounted) {
        final currentLocale = Localizations.localeOf(context).languageCode;
        context.go('/$currentLocale/home');
      }
    } catch (e) {
      if (kDebugMode) {
        print('OAuth2 callback error: $e');
      }
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Processing login...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
            : _errorMessage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Login failed',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          final currentLocale = Localizations.localeOf(context).languageCode;
                          context.go('/$currentLocale/login');
                        },
                        child: const Text('Back to Login'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}