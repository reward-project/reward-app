import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';
import '../../providers/api_provider.dart';
// import '../../services/dio_service.dart'; // 제거됨 - reward_common 사용
import 'package:reward_common/reward_common.dart';
import '../../theme/app_theme.dart';
// import '../../widgets/modern_widgets.dart'; // reward_common으로 이동됨
import 'package:reward_common/utils/context_extensions.dart';

class MyPageScreenModern extends StatefulWidget {
  const MyPageScreenModern({super.key});

  @override
  State<MyPageScreenModern> createState() => _MyPageScreenModernState();
}

class _MyPageScreenModernState extends State<MyPageScreenModern>
    with TickerProviderStateMixin {
  String _userNickname = '';
  String _userEmail = '';
  String _userName = '';
  int _point = 0;
  bool _isLoading = true;
  late AnimationController _pointAnimationController;
  late AnimationController _profileAnimationController;

  final List<({IconData icon, String title, String? subtitle, String route, Color color})> _menuItems = [
    (icon: Icons.person_outline, title: '프로필 수정', subtitle: '개인정보 관리', route: '/profile-edit', color: Colors.blue),
    (icon: Icons.receipt_long_outlined, title: '포인트 내역', subtitle: '적립 및 사용 내역', route: '/cash-history', color: Colors.green),
    (icon: Icons.card_giftcard_outlined, title: '리워드 스토어', subtitle: '포인트로 상품 구매', route: '/reward-store', color: Colors.orange),
    (icon: Icons.notifications_outlined, title: '알림 설정', subtitle: '푸시 알림 관리', route: '/notification-settings', color: Colors.purple),
    (icon: Icons.help_outline, title: '고객센터', subtitle: 'FAQ 및 문의하기', route: '/support', color: Colors.teal),
    (icon: Icons.privacy_tip_outlined, title: '이용약관', subtitle: '서비스 약관 및 정책', route: '/terms', color: Colors.indigo),
  ];

  @override
  void initState() {
    super.initState();
    _pointAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fetchUserInfo();
  }

  @override
  void dispose() {
    _pointAnimationController.dispose();
    _profileAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AppAuthProvider>();
      final user = await authProvider.userInfo;
      
      if (user != null && mounted) {
        setState(() {
          _userNickname = user.name ?? '';
          _userEmail = user.email ?? '';
          _userName = user.name ?? '';
        });
      }

      // 포인트는 별도 API로 가져오기
      try {
        final apiResponse = await context.apiService.getWrapped<Map<String, dynamic>>(
          '/members/me/point',
        );

        if (apiResponse.success && apiResponse.data != null && mounted) {
          final newPoint = (apiResponse.data!['point'] as num?)?.toInt() ?? 0;
          setState(() {
            _point = newPoint;
          });
          _pointAnimationController.forward();
          _profileAnimationController.forward();
        }
      } catch (e) {
        print('Error fetching point: $e');
        if (mounted) {
          setState(() {
            _point = 0;
          });
        }
      }
    } catch (e) {
      print('Error fetching user info: $e');
      if (mounted) {
        setState(() {
          _userNickname = '사용자';
          _userEmail = '';
          _userName = '';
          _point = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final authProvider = context.read<AppAuthProvider>();
        await authProvider.logout();

        if (mounted) {
          final currentLocale = Localizations.localeOf(context).languageCode;
          context.go('/$currentLocale/login');
        }
      } catch (e) {
        print('Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.surface,
              context.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchUserInfo,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 프로필 헤더
                  _buildProfileHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // 메뉴 리스트
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimationLimiter(
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            ..._menuItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildMenuItem(
                                icon: item.icon,
                                title: item.title,
                                subtitle: item.subtitle,
                                color: item.color,
                                onTap: () {
                                  if (item.route == '/cash-history') {
                                    context.go('/$currentLocale/cash-history');
                                  } else if (item.route == '/profile-edit') {
                                    context.go('/$currentLocale/profile-edit');
                                  }
                                  // 다른 라우트들은 추후 구현
                                },
                              ),
                            )),
                            const SizedBox(height: 8),
                            _buildLogoutButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 프로필 이미지
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _profileAnimationController,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colorScheme.primaryContainer,
                    context.colorScheme.secondaryContainer,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _userNickname.isNotEmpty ? _userNickname[0].toUpperCase() : '?',
                  style: context.textTheme.displayMedium?.copyWith(
                    color: context.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ).animate()
            .scale(delay: 200.ms, duration: 600.ms),
          
          const SizedBox(height: 16),
          
          // 사용자 정보
          Column(
            children: [
              Text(
                _userName.isNotEmpty ? _userName : _userNickname,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
              ).animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.2, end: 0),
              if (_userEmail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ).animate()
                  .fadeIn(delay: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 포인트 카드
          ModernCard(
            useGlassEffect: true,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '보유 포인트',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _pointAnimationController,
                      builder: (context, child) {
                        final animatedValue = (_pointAnimationController.value * _point).toInt();
                        return Text(
                          '${animatedValue.toString().replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )}P',
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: context.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(delay: 600.ms)
            .slideX(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ModernCard(
      onTap: _handleLogout,
      backgroundColor: context.colorScheme.errorContainer.withOpacity(0.3),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.logout,
              color: context.colorScheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '로그아웃',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}