import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/settlement.dart';
import '../../services/settlement_service.dart';
import '../../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';
import '../../constants/styles.dart';

class SettlementHistoryScreen extends StatefulWidget {
  const SettlementHistoryScreen({super.key});

  @override
  State<SettlementHistoryScreen> createState() =>
      _SettlementHistoryScreenState();
}

class _SettlementHistoryScreenState extends State<SettlementHistoryScreen>
    with SingleTickerProviderStateMixin {
  final SettlementService _settlementService = SettlementService();
  final AuthProvider _authProvider = AuthProvider();
  late TabController _tabController;

  List<SettlementResponse> _settlements = [];
  PageResponse<RewardHistoryResponse>? _rewardHistory;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  int _currentPage = 0;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _tabController.index == 1 &&
          _rewardHistory != null &&
          !_rewardHistory!.last) {
        _loadMoreRewardHistory();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 정산 신청 내역과 리워드 내역을 동시에 로드
      final futures = await Future.wait([
        _settlementService.getMySettlements(int.parse(userId)),
        _settlementService.getRewardHistory(
          int.parse(userId),
          page: 0,
          size: _pageSize,
          sort: 'createdAt,desc',
        ),
      ]);

      if (mounted) {
        setState(() {
          _settlements = futures[0] as List<SettlementResponse>;
          _rewardHistory = futures[1] as PageResponse<RewardHistoryResponse>;
          _currentPage = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 로딩 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreRewardHistory() async {
    if (_isLoadingMore || _rewardHistory?.last == true) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) return;

      final nextPage = await _settlementService.getRewardHistory(
        int.parse(userId),
        page: _currentPage + 1,
        size: _pageSize,
        sort: 'createdAt,desc',
      );

      if (mounted) {
        setState(() {
          _rewardHistory = PageResponse<RewardHistoryResponse>(
            content: [..._rewardHistory!.content, ...nextPage.content],
            totalElements: nextPage.totalElements,
            totalPages: nextPage.totalPages,
            number: nextPage.number,
            size: nextPage.size,
            first: _rewardHistory!.first,
            last: nextPage.last,
          );
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추가 데이터 로딩 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSettlementHistory() {
    if (_settlements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '정산 신청 내역이 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _settlements.length,
      itemBuilder: (context, index) {
        final settlement = _settlements[index];
        return _buildSettlementCard(settlement);
      },
    );
  }

  Widget _buildSettlementCard(SettlementResponse settlement) {
    Color statusColor;
    IconData statusIcon;
    
    switch (settlement.status) {
      case SettlementStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case SettlementStatus.processing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case SettlementStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case SettlementStatus.cancelled:
      case SettlementStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/settlement/status',
            arguments: settlement.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '정산 ID: ${settlement.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          settlement.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.monetization_on, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '정산 금액: ${NumberFormat('#,###').format(settlement.amount)}원',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '신청일: ${DateFormat('yyyy-MM-dd HH:mm').format(settlement.createdAt)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              
              if (settlement.scheduledDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '예정일: ${DateFormat('yyyy-MM-dd').format(settlement.scheduledDate!)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
              
              if (settlement.message != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    settlement.message!,
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardHistory() {
    if (_rewardHistory == null || _rewardHistory!.content.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '리워드 내역이 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _rewardHistory!.content.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _rewardHistory!.content.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final reward = _rewardHistory!.content[index];
        return _buildRewardCard(reward);
      },
    );
  }

  Widget _buildRewardCard(RewardHistoryResponse reward) {
    Color statusColor;
    IconData statusIcon;
    
    switch (reward.status) {
      case RewardStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case RewardStatus.processing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case RewardStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RewardStatus.hold:
        statusColor = Colors.amber;
        statusIcon = Icons.pause_circle;
        break;
      case RewardStatus.cancelled:
      case RewardStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reward.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        reward.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reward.rewardType,
                    style: TextStyle(
                      color: Colors.purple[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${NumberFormat('#,###').format(reward.amount)}원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(reward.createdAt),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            
            if (reward.settlementDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event_available, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '정산일: ${DateFormat('yyyy-MM-dd').format(reward.settlementDate!)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 내역'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '정산 신청'),
            Tab(text: '리워드 내역'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildSettlementHistory(),
                ),
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildRewardHistory(),
                ),
              ],
            ),
    );
  }
}