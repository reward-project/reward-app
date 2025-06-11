import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../contexts/auth_context.dart';

/// 고객용 회원가입 페이지
/// 모바일에서만 네이티브 회원가입을 지원합니다.
class RegisterPage extends HookConsumerWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final showPassword = useState(false);
    final showConfirmPassword = useState(false);

    // 플랫폼 체크
    final isWebPlatform = kIsWeb;

    // 회원가입 처리
    final handleRegister = useCallback(() async {
      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        errorMessage.value = '모든 필드를 입력해주세요.';
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = '비밀번호가 일치하지 않습니다.';
        return;
      }

      if (passwordController.text.length < 6) {
        errorMessage.value = '비밀번호는 최소 6자리 이상이어야 합니다.';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        // 네이티브 인증으로 전환
        ref.read(authMethodProvider.notifier).state = AuthMethod.native;
        
        final success = await ref.read(authContextProvider.notifier).register(
          email: emailController.text,
          password: passwordController.text,
          name: nameController.text,
        );

        if (success) {
          // 회원가입 성공 - 홈으로 이동
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          errorMessage.value = '회원가입에 실패했습니다. 다시 시도해주세요.';
        }
      } catch (e) {
        errorMessage.value = '회원가입 중 오류가 발생했습니다: ${e.toString()}';
      } finally {
        isLoading.value = false;
      }
    }, [
      nameController.text,
      emailController.text,
      passwordController.text,
      confirmPasswordController.text,
    ]);

    // 웹에서는 회원가입 페이지를 보여주지 않음
    if (isWebPlatform) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('회원가입'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.web,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  '웹에서는 회원가입이 지원되지 않습니다.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'SSO 로그인을 이용하거나\n모바일 앱에서 계정을 생성해주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('로그인 페이지로 돌아가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더
              const SizedBox(height: 20),
              const Icon(
                Icons.person_add,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Reward App 가입하기',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '새로운 계정을 만들어 리워드를 받아보세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 에러 메시지
              if (errorMessage.value != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    errorMessage.value!,
                    style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 이름 입력
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '이름',
                  hintText: '홍길동',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 이메일 입력
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '이메일',
                  hintText: 'user@example.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호 입력
              TextField(
                controller: passwordController,
                obscureText: !showPassword.value,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  hintText: '최소 6자리 이상',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword.value ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => showPassword.value = !showPassword.value,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호 확인 입력
              TextField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword.value,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  hintText: '비밀번호를 다시 입력하세요',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirmPassword.value ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => showConfirmPassword.value = !showConfirmPassword.value,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 회원가입 버튼
              ElevatedButton(
                onPressed: isLoading.value ? null : handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '계정 만들기',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 24),

              // 이미 계정이 있는 경우
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('이미 계정이 있으신가요? '),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('로그인'),
                  ),
                ],
              ),

              // 약관 동의 (간단한 버전)
              const SizedBox(height: 16),
              Text(
                '계정을 생성하면 이용약관 및 개인정보처리방침에 동의하는 것으로 간주됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}