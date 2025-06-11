import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';
import '../../providers/api_provider.dart';
// import '../../services/dio_service.dart'; // 제거됨 - reward_common 사용
import 'package:reward_common/reward_common.dart';
// import '../../widgets/modern_widgets.dart'; // reward_common으로 이동됨
import '../../theme/app_theme.dart';
import 'package:reward_common/utils/context_extensions.dart';

class HomePageModern extends StatefulWidget {
  final Locale locale;

  const HomePageModern({super.key, required this.locale});

  @override
  State<HomePageModern> createState() => _HomePageModernState();
}

class _HomePageModernState extends State<HomePageModern> with TickerProviderStateMixin {
  int _point = 0;
  int _previousPoint = 0;
  String _userNickname = '';
  bool _isLoading = true;
  late AnimationController _pointAnimationController;
  late Animation<int> _pointAnimation;
  bool _pointAnimationInitialized = false;
  
  // 주간 포인트 데이터 (샘플)
  final List<FlSpot> _weeklyPoints = [
    const FlSpot(0, 100),
    const FlSpot(1, 150),
    const FlSpot(2, 180),
    const FlSpot(3, 220),
    const FlSpot(4, 250),
    const FlSpot(5, 300),
    const FlSpot(6, 350),
  ];

  @override
  void initState() {
    super.initState();
    _pointAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fetchUserInfo();
  }

  @override
  void dispose() {
    _pointAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AppAuthProvider>();
      final user = await authProvider.userInfo;
      
      if (user != null) {
        setState(() {
          _userNickname = user.name ?? '';
        });
      }

      try {
        final apiResponse = await context.apiService.getWrapped<Map<String, dynamic>>(
          '/members/me/point',
        );

        if (apiResponse.success && apiResponse.data != null) {
          final newPoint = (apiResponse.data!['point'] as num?)?.toInt() ?? 0;
          
          // 포인트 애니메이션 설정
          _pointAnimation = IntTween(
            begin: _previousPoint,
            end: newPoint,
          ).animate(CurvedAnimation(
            parent: _pointAnimationController,
            curve: Curves.easeOutQuart,
          ));
          
          _pointAnimationInitialized = true;
          _pointAnimationController.forward(from: 0);
          
          setState(() {
            _point = newPoint;
            _previousPoint = newPoint;
          });
        }
      } catch (e) {
        // 포인트 정보를 가져오지 못한 경우 기본값으로 초기화
        _pointAnimation = IntTween(
          begin: 0,
          end: 0,
        ).animate(CurvedAnimation(
          parent: _pointAnimationController,
          curve: Curves.easeOutQuart,
        ));
        _pointAnimationInitialized = true;
        
        setState(() => _point = 0);
      }
    } catch (e) {
      setState(() => _userNickname = '사용자');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = widget.locale.languageCode;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ModernAppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          child: CircleAvatar(
            backgroundColor: context.colorScheme.primaryContainer,
            child: Text(
              _userNickname.isNotEmpty ? _userNickname[0] : '?',
              style: TextStyle(
                color: context.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: context.colorScheme.onSurface),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.colorScheme.onSurface),
            onPressed: () => context.go('/$currentLocale/mypage'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colorScheme.primaryContainer.withOpacity(0.1),
              context.colorScheme.secondaryContainer.withOpacity(0.05),
              context.colorScheme.surface,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _fetchUserInfo,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    const SizedBox(height: 100),
                    
                    // Welcome Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '안녕하세요,',
                            style: context.textTheme.headlineSmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '$_userNickname님!',
                            style: context.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Point Card with Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPointCard(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '빠른 메뉴',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActions(currentLocale),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Feature Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '추천 활동',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureCards(currentLocale),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointCard() {
    return ModernCard(
      useGlassEffect: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '내 포인트',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _pointAnimationInitialized
                      ? AnimatedBuilder(
                          animation: _pointAnimation,
                          builder: (context, child) {
                            return Text(
                              '${_pointAnimation.value}P',
                              style: context.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.primary,
                              ),
                            );
                          },
                        )
                      : Text(
                          '${_point}P',
                          style: context.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.primary,
                          ),
                        ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.successContainer,
                  borderRadius: context.radiusCircular,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: context.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Mini Chart
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyPoints,
                    isCurved: true,
                    color: context.colorScheme.primary,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.colorScheme.primary.withOpacity(0.1),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이번 주 적립: 250P',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              ModernButton(
                text: '포인트 내역',
                onPressed: () => context.go('/${widget.locale.languageCode}/cash-history'),
                filled: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 32,
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickActions(String currentLocale) {
    final actions = [
      {'icon': Icons.rocket_launch, 'label': '오늘의 미션', 'route': '/$currentLocale/mission-list', 'color': context.colorScheme.primary},
      {'icon': Icons.account_balance_wallet, 'label': '적립하기', 'route': null, 'color': context.colorScheme.secondary},
      {'icon': Icons.card_giftcard, 'label': '리워드 샵', 'route': null, 'color': context.colorScheme.tertiary},
      {'icon': Icons.leaderboard, 'label': '랭킹', 'route': null, 'color': context.colorScheme.error},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionItem(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          onTap: action['route'] != null ? () => context.go(action['route'] as String) : () {},
          color: action['color'] as Color,
          index: index,
        );
      },
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required int index,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: context.radiusLarge,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: context.radiusLarge,
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: context.textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms)
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Widget _buildFeatureCards(String currentLocale) {
    return Column(
      children: [
        ModernCard(
          onTap: () => context.go('/$currentLocale/missions'),
          backgroundColor: context.colorScheme.primaryContainer,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withOpacity(0.2),
                    borderRadius: context.radiusMedium,
                  ),
                  child: Icon(
                    Icons.task_alt,
                    size: 32,
                    color: context.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '미션 도전하기',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '새로운 미션이 3개 기다리고 있어요!',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ModernCard(
                onTap: () {},
                backgroundColor: context.colorScheme.secondaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 32,
                      color: context.colorScheme.secondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '이벤트',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '진행중 2개',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSecondaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ModernCard(
                onTap: () {},
                backgroundColor: context.colorScheme.tertiaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.people,
                      size: 32,
                      color: context.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '친구 초대',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1,000P 받기',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onTertiaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}