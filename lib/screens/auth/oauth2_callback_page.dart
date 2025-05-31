import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/dio_service.dart';
import '../../config/app_config.dart';
import '../../models/api_response.dart';
import '../../models/token_dto.dart';

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

      // Exchange code for tokens
      final dio = DioService.instance;
      final response = await dio.post(
        '${AppConfig.authServerUrl}/oauth2/token',
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': AppConfig.oauth2RedirectUri,
          'client_id': AppConfig.oauth2ClientId,
          // Add code_verifier if using PKCE
          // 'code_verifier': _codeVerifier, // Retrieved from storage
        },
      );

      final tokenData = response.data;
      
      if (kDebugMode) {
        print('Token response: $tokenData');
      }

      // Extract tokens
      final accessToken = tokenData['access_token'];
      final refreshToken = tokenData['refresh_token'];
      
      if (accessToken == null) {
        throw Exception('No access token received');
      }

      // Store tokens in AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

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