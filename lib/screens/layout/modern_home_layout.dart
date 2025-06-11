import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
// import '../../widgets/modern_widgets.dart'; // reward_common으로 이동됨
import 'package:reward_common/reward_common.dart';
import 'package:reward_common/utils/context_extensions.dart';
import 'package:reward_common/utils/responsive.dart';

class ModernHomeLayout extends StatefulWidget {
  final Widget child;

  const ModernHomeLayout({super.key, required this.child});

  @override
  State<ModernHomeLayout> createState() => _ModernHomeLayoutState();
}

class _ModernHomeLayoutState extends State<ModernHomeLayout> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _railAnimationController;
  late AnimationController _fabAnimationController;
  bool _railExtended = false;

  @override
  void initState() {
    super.initState();
    _railAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _railAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    final currentLocale = Localizations.localeOf(context).languageCode;
    switch (index) {
      case 0:
        context.go('/$currentLocale/home');
        break;
      case 1:
        context.go('/$currentLocale/missions');
        break;
      case 2:
        context.go('/$currentLocale/cash-history');
        break;
      case 3:
        context.go('/$currentLocale/settlement');
        break;
      case 4:
        context.go('/$currentLocale/mypage');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !isMobile(context);
    final currentRoute = GoRouterState.of(context).uri.path;
    
    // 현재 라우트에 따라 선택된 인덱스 설정
    if (currentRoute.contains('/home')) _selectedIndex = 0;
    else if (currentRoute.contains('/missions') || currentRoute.contains('/mission-list')) _selectedIndex = 1;
    else if (currentRoute.contains('/cash-history') || currentRoute.contains('/withdrawal-request')) _selectedIndex = 2;
    else if (currentRoute.contains('/settlement')) _selectedIndex = 3;
    else if (currentRoute.contains('/mypage')) _selectedIndex = 4;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.surface,
              context.colorScheme.surface.withOpacity(0.8),
              context.colorScheme.surface,
            ],
          ),
        ),
        child: Row(
          children: [
            // 데스크탑용 Navigation Rail
            if (isDesktop)
              MouseRegion(
                onEnter: (_) {
                  setState(() => _railExtended = true);
                  _railAnimationController.forward();
                },
                onExit: (_) {
                  setState(() => _railExtended = false);
                  _railAnimationController.reverse();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _railExtended ? 260 : 80,
                  child: NavigationRail(
                    extended: _railExtended,
                    backgroundColor: context.colorScheme.surface.withOpacity(0.3),
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onDestinationSelected,
                    indicatorColor: context.colorScheme.primaryContainer,
                    selectedIconTheme: IconThemeData(
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    labelType: _railExtended ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
                    leading: _buildRailHeader(),
                    trailing: _buildRailTrailing(),
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home_rounded),
                        label: const Text('홈'),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.rocket_launch_outlined),
                        selectedIcon: const Icon(Icons.rocket_launch_rounded),
                        label: const Text('미션'),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
                        label: const Text('포인트'),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.monetization_on_outlined),
                        selectedIcon: const Icon(Icons.monetization_on_rounded),
                        label: const Text('정산'),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.person_outline_rounded),
                        selectedIcon: const Icon(Icons.person_rounded),
                        label: const Text('마이페이지'),
                      ),
                    ],
                  ),
                ),
              ),

            // 메인 콘텐츠
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
      
      // 모바일용 Modern Bottom Navigation Bar
      bottomNavigationBar: isMobile(context) ? _buildModernBottomNav() : null,
      
      // Floating Action Button 제거 (정산 메뉴가 추가되어 필요 없음)
    );
  }

  Widget _buildRailHeader() {
    return Column(
      children: [
        const SizedBox(height: 24),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(_railExtended ? 24 : 12),
          child: _railExtended
              ? Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.colorScheme.primary,
                            context.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reward Factory',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ],
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.colorScheme.primary,
                        context.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildRailTrailing() {
    if (!_railExtended) return const SizedBox.shrink();
    
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ModernCard(
                  useGlassEffect: true,
                  backgroundColor: context.colorScheme.primaryContainer.withOpacity(0.3),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘의 팁',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '미션을 완료하고\n포인트를 받아보세요!',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ColorFilter.mode(
            context.colorScheme.surface.withOpacity(0.8),
            BlendMode.srcOver,
          ),
          child: NavigationBar(
            height: 80,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: context.colorScheme.primaryContainer,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined).animate()
                  .fadeIn(duration: 300.ms)
                  .scale(delay: 100.ms),
                selectedIcon: const Icon(Icons.home_rounded).animate()
                  .fadeIn(duration: 300.ms)
                  .scale(delay: 100.ms),
                label: '홈',
              ),
              NavigationDestination(
                icon: const Icon(Icons.rocket_launch_outlined).animate()
                  .fadeIn(duration: 300.ms, delay: 50.ms)
                  .scale(delay: 150.ms),
                selectedIcon: const Icon(Icons.rocket_launch_rounded).animate()
                  .fadeIn(duration: 300.ms, delay: 50.ms)
                  .scale(delay: 150.ms),
                label: '미션',
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined).animate()
                  .fadeIn(duration: 300.ms, delay: 75.ms)
                  .scale(delay: 175.ms),
                selectedIcon: const Icon(Icons.account_balance_wallet_rounded).animate()
                  .fadeIn(duration: 300.ms, delay: 75.ms)
                  .scale(delay: 175.ms),
                label: '포인트',
              ),
              NavigationDestination(
                icon: const Icon(Icons.monetization_on_outlined).animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms)
                  .scale(delay: 200.ms),
                selectedIcon: const Icon(Icons.monetization_on_rounded).animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms)
                  .scale(delay: 200.ms),
                label: '정산',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded).animate()
                  .fadeIn(duration: 300.ms, delay: 125.ms)
                  .scale(delay: 225.ms),
                selectedIcon: const Icon(Icons.person_rounded).animate()
                  .fadeIn(duration: 300.ms, delay: 125.ms)
                  .scale(delay: 225.ms),
                label: '마이',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
      child: FloatingActionButton(
        onPressed: () {
          // 포인트 적립 액션
          _showRewardBottomSheet();
        },
        backgroundColor: context.colorScheme.primary,
        elevation: 4,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colorScheme.primary,
                context.colorScheme.secondary,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_circle_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
      ).animate()
        .shimmer(duration: 2000.ms, delay: 1000.ms)
        .shake(hz: 2, curve: Curves.easeInOutCubic, delay: 3000.ms),
    );
  }

  void _showRewardBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '포인트 적립하기',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildRewardOption(
              icon: Icons.qr_code_scanner,
              title: 'QR 코드 스캔',
              subtitle: '매장에서 QR 코드를 스캔하세요',
              color: context.colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                // QR 스캔 기능
              },
            ),
            const SizedBox(height: 12),
            _buildRewardOption(
              icon: Icons.receipt_long,
              title: '영수증 인증',
              subtitle: '구매 영수증을 촬영하세요',
              color: context.colorScheme.secondary,
              onTap: () {
                Navigator.pop(context);
                // 영수증 인증 기능
              },
            ),
            const SizedBox(height: 12),
            _buildRewardOption(
              icon: Icons.code,
              title: '코드 입력',
              subtitle: '프로모션 코드를 입력하세요',
              color: context.colorScheme.tertiary,
              onTap: () {
                Navigator.pop(context);
                // 코드 입력 기능
              },
            ),
            SafeArea(child: const SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
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
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}