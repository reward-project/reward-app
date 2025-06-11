import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import '../../services/dio_service.dart'; // 제거됨 - reward_common 사용
import 'package:reward_common/reward_common.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_theme.dart';
// import '../../widgets/modern_widgets.dart'; // reward_common으로 이동됨
import 'package:intl/intl.dart';
import 'package:reward_common/utils/context_extensions.dart';

class CashHistory {
  final int id;
  final double amount;
  final String type;
  final String description;
  final DateTime createdAt;
  final double balance;

  CashHistory({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    required this.balance,
  });

  factory CashHistory.fromJson(Map<String, dynamic> json) {
    return CashHistory(
      id: json['id'],
      amount: json['amount'].toDouble(),
      type: json['type'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      balance: json['balance'].toDouble(),
    );
  }
}

class CashHistoryScreenModern extends StatefulWidget {
  const CashHistoryScreenModern({super.key});

  @override
  State<CashHistoryScreenModern> createState() => _CashHistoryScreenModernState();
}

class _CashHistoryScreenModernState extends State<CashHistoryScreenModern>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _chartAnimationController;
  final ScrollController _scrollController = ScrollController();
  List<CashHistory> _histories = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  String _currentType = 'ALL';
  static const int _pageSize = 20;
  
  // 통계 데이터
  double _totalEarned = 0;
  double _totalSpent = 0;
  double _currentBalance = 0;
  List<FlSpot> _chartData = [];

  final List<({IconData icon, String label, String value})> _filterOptions = [
    (icon: Icons.all_inclusive, label: '전체', value: 'ALL'),
    (icon: Icons.account_balance_wallet, label: '출금/충전', value: 'PAYMENT'),
    (icon: Icons.add_circle_outline, label: '적립', value: 'EARN'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_handleScroll);
    _fetchCashHistory(refresh: true);
    _generateChartData();
  }

  void _generateChartData() {
    // 샘플 차트 데이터 (실제로는 API에서 가져와야 함)
    _chartData = [
      const FlSpot(0, 50000),
      const FlSpot(1, 52000),
      const FlSpot(2, 48000),
      const FlSpot(3, 55000),
      const FlSpot(4, 53000),
      const FlSpot(5, 58000),
      const FlSpot(6, 60000),
    ];
    _chartAnimationController.forward();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;
    
    setState(() {
      _currentType = _filterOptions[_tabController.index].value;
      _histories = [];
      _currentPage = 0;
      _hasMore = true;
      _isLoading = false;
    });
    
    _fetchCashHistory(refresh: true);
  }

  void _handleScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _fetchCashHistory(refresh: false);
      }
    }
  }

  Future<void> _fetchCashHistory({required bool refresh}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiResponse = await context.apiService.getWrapped<Map<String, dynamic>>(
        '/members/me/cash-history',
        queryParameters: {
          'type': _currentType,
          'page': refresh ? 0 : _currentPage,
          'size': _pageSize,
        },
      );

      if (apiResponse.success && apiResponse.data != null) {
        final content = apiResponse.data!['content'] as List;
        final totalPages = apiResponse.data!['totalPages'] as int;
        
        setState(() {
          if (refresh) {
            _histories = content.map((data) => CashHistory.fromJson(data)).toList();
            _currentPage = 1;
            _calculateStatistics();
          } else {
            _histories.addAll(content.map((data) => CashHistory.fromJson(data)).toList());
            _currentPage++;
          }
          _hasMore = _currentPage < totalPages;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching cash history: $e');
      }
      // 샘플 데이터로 대체
      _loadSampleData();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadSampleData() {
    final now = DateTime.now();
    _histories = List.generate(10, (index) {
      final isEarn = index % 3 == 0;
      return CashHistory(
        id: index,
        amount: (index + 1) * 1000.0,
        type: isEarn ? 'EARN' : 'PAYMENT',
        description: isEarn ? '미션 완료 보상' : '포인트 사용',
        createdAt: now.subtract(Duration(days: index)),
        balance: 50000 - (index * 500),
      );
    });
    _calculateStatistics();
  }

  void _calculateStatistics() {
    _totalEarned = 0;
    _totalSpent = 0;
    
    for (var history in _histories) {
      if (history.type == 'EARN') {
        _totalEarned += history.amount;
      } else {
        _totalSpent += history.amount;
      }
    }
    
    if (_histories.isNotEmpty) {
      _currentBalance = _histories.first.balance;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorColor: context.colorScheme.primary,
                    labelColor: context.colorScheme.primary,
                    unselectedLabelColor: context.colorScheme.onSurfaceVariant,
                    tabs: _filterOptions.map((option) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(option.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(option.label),
                        ],
                      ),
                    )).toList(),
                  ),
                  context.colorScheme.surface,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: List.generate(3, (_) => _buildHistoryList()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '포인트 내역',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface,
            ),
          ).animate()
            .fadeIn(duration: 500.ms)
            .slideX(begin: -0.2, end: 0),
          const SizedBox(height: 24),
          
          // 잔액 카드
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colorScheme.primaryContainer,
                  context.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '현재 잔액',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormat('#,###').format(_currentBalance)}P',
                          style: context.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 32,
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 미니 차트
                SizedBox(
                  height: 60,
                  child: AnimatedBuilder(
                    animation: _chartAnimationController,
                    builder: (context, child) {
                      return LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartData,
                              isCurved: true,
                              color: Colors.white,
                              barWidth: 3,
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          minY: 0,
                          clipData: FlClipData(
                            top: true,
                            bottom: true,
                            left: false,
                            right: false,
                          ),
                        ),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.linear,
                      );
                    },
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 16),
          
          // 통계 카드들
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  label: '총 적립',
                  value: '${NumberFormat('#,###').format(_totalEarned)}P',
                  color: Colors.green,
                  index: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_down,
                  label: '총 사용',
                  value: '${NumberFormat('#,###').format(_totalSpent)}P',
                  color: Colors.red,
                  index: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int index,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 400 + (100 * index)))
      .slideX(begin: index == 0 ? -0.1 : 0.1, end: 0);
  }

  Widget _buildHistoryList() {
    if (_histories.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '거래 내역이 없습니다',
              style: TextStyle(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCashHistory(refresh: true),
      child: AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _histories.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _histories.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final history = _histories[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildHistoryItem(history),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryItem(CashHistory history) {
    final isEarn = history.type == 'EARN';
    final icon = isEarn ? Icons.add_circle : Icons.remove_circle;
    final color = isEarn ? Colors.green : Colors.red;

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.description,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MM월 dd일 HH:mm').format(history.createdAt),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarn ? '+' : '-'}${NumberFormat('#,###').format(history.amount)}P',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '잔액: ${NumberFormat('#,###').format(history.balance)}P',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}