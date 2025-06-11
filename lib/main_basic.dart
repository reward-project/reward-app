import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  AppConfig.initialize(env == 'prod' ? Environment.prod : Environment.dev);

  runApp(const BasicTestApp());
}

class BasicTestApp extends StatelessWidget {
  const BasicTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '구글 로그인 기본 테스트',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BasicLoginPage(),
    );
  }
}

class BasicLoginPage extends StatefulWidget {
  const BasicLoginPage({super.key});

  @override
  State<BasicLoginPage> createState() => _BasicLoginPageState();
}

class _BasicLoginPageState extends State<BasicLoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: AppConfig.googleWebClientId,
  );

  String _status = '구글 로그인 준비됨';

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _status = '🚀 구글 로그인 시작...';
      });
      
      if (kDebugMode) print('🚀 구글 로그인 시작...');
      
      // 이전 세션 정리
      await _googleSignIn.signOut();
      
      setState(() {
        _status = '📱 구글 로그인 UI 호출 중...';
      });
      
      if (kDebugMode) print('📱 구글 로그인 UI 호출 중...');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() {
          _status = '❌ 사용자가 로그인을 취소했습니다';
        });
        if (kDebugMode) print('❌ 사용자가 Google 로그인을 취소했습니다');
        return;
      }
      
      setState(() {
        _status = '✅ 구글 계정 선택 완료: ${googleUser.email}';
      });
      
      if (kDebugMode) print('✅ Google 계정 선택 완료: ${googleUser.email}');
      
      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        setState(() {
          _status = '❌ Google ID Token을 가져올 수 없습니다';
        });
        if (kDebugMode) print('❌ Google ID Token을 가져올 수 없습니다');
        return;
      }
      
      setState(() {
        _status = '🎉 구글 로그인 성공!\nID Token: ${googleAuth.idToken!.substring(0, 50)}...';
      });
      
      if (kDebugMode) {
        print('🎉 구글 로그인 성공!');
        print('ID Token: ${googleAuth.idToken!.substring(0, 50)}...');
        print('Access Token: ${googleAuth.accessToken?.substring(0, 50)}...');
      }
      
    } catch (e) {
      setState(() {
        _status = '❌ 구글 로그인 에러: $e';
      });
      
      if (kDebugMode) {
        print('❌ Google 로그인 중 오류 발생: $e');
        print('❌ 오류 타입: ${e.runtimeType}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구글 로그인 기본 테스트'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _handleGoogleSignIn,
                icon: const Icon(Icons.login),
                label: const Text('구글 로그인 테스트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '디버그 정보:\nServer Client ID: ${AppConfig.googleWebClientId.substring(0, 20)}...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}