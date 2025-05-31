import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class NaverLoginButton extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onLoginFailure;

  const NaverLoginButton({
    super.key,
    this.onLoginSuccess,
    this.onLoginFailure,
  });

  @override
  State<NaverLoginButton> createState() => _NaverLoginButtonState();
}

class _NaverLoginButtonState extends State<NaverLoginButton> {
  bool _isLoading = false;

  Future<void> _handleNaverLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.loginWithNaver();

      if (success && mounted) {
        widget.onLoginSuccess?.call();
      } else if (mounted) {
        widget.onLoginFailure?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('네이버 로그인에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        widget.onLoginFailure?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('네이버 로그인 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleNaverLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF03C75A), // 네이버 그린
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/naver.svg',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.account_circle,
                        size: 24,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '네이버로 로그인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}