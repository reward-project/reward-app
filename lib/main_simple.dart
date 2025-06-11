import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/auth_provider_extended.dart';
import 'services/google_login_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  AppConfig.initialize(env == 'prod' ? Environment.prod : Environment.dev);

  if (kDebugMode) {
    print('🌍 Environment: ${env == 'prod' ? 'Production' : 'Development'}');
    print('🌐 Backend URL: ${AppConfig.apiBaseUrl}${AppConfig.apiPath}');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AppAuthProvider(context)..initializeAuth(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '리워드 팩토리',
      theme: AppTheme.lightTheme(null),
      home: const LoginTestPage(),
    );
  }
}

class LoginTestPage extends StatelessWidget {
  const LoginTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구글 로그인 테스트'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '구글 로그인 테스트',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                print('🔵 구글 로그인 버튼 클릭됨');
                try {
                  final result = await GoogleLoginService.signIn();
                  if (result != null) {
                    print('✅ 구글 로그인 성공!');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구글 로그인 성공!')),
                    );
                  } else {
                    print('❌ 구글 로그인 실패');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구글 로그인 실패')),
                    );
                  }
                } catch (e) {
                  print('❌ 구글 로그인 에러: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('구글 로그인 에러: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                minimumSize: const Size(200, 48),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Google로 로그인'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}