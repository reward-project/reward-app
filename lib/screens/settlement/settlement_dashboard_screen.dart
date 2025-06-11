import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/settlement.dart';
import '../../services/settlement_service.dart';
import '../../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';
import 'package:reward_common/widgets/common/filled_text_field.dart';
import '../../constants/styles.dart';

class SettlementDashboardScreen extends StatefulWidget {
  const SettlementDashboardScreen({super.key});

  @override
  State<SettlementDashboardScreen> createState() =>
      _SettlementDashboardScreenState();
}

class _SettlementDashboardScreenState extends State<SettlementDashboardScreen> {
  final SettlementService _settlementService = SettlementService();
  final AuthProvider _authProvider = AuthProvider();
  
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  
  double _settlableAmount = 0.0;
  List<SettlementResponse> _recentSettlements = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 정산 가능 금액 조회
      final amountResponse = await _settlementService.getSettlableAmount(
        int.parse(userId),
      );
      
      // 최근 정산 내역 조회
      final settlements = await _settlementService.getMySettlements(
        int.parse(userId),
      );

      if (mounted) {
        setState(() {
          _settlableAmount = amountResponse.amount;
          _recentSettlements = settlements.take(5).toList();
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

  Future<void> _submitSettlementRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정산 기간을 선택해 주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final request = SettlementRequest(
        periodStartDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        periodEndDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        bankName: _bankNameController.text,
        accountNumber: _accountNumberController.text,
        accountHolder: _accountHolderController.text,
      );

      await _settlementService.requestSettlement(
        int.parse(userId),
        request,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정산 신청이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 폼 초기화
        _formKey.currentState!.reset();
        _bankNameController.clear();
        _accountNumberController.clear();
        _accountHolderController.clear();
        _startDate = null;
        _endDate = null;
        
        // 데이터 새로고침
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정산 신청 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildSettlableAmountCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  '정산 가능 금액',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${NumberFormat('#,###').format(_settlableAmount)}원',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '현재 정산 신청 가능한 금액입니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.request_quote, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Text(
                    '정산 신청',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 정산 기간 선택
              const Text('정산 기간', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat('yyyy-MM-dd').format(_startDate!)
                              : '시작일 선택',
                          style: TextStyle(
                            color: _startDate != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('~'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                              : '종료일 선택',
                          style: TextStyle(
                            color: _endDate != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 계좌 정보
              FilledTextField(
                controller: _bankNameController,
                labelText: '은행명',
                hintText: '예: 국민은행',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '은행명을 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              FilledTextField(
                controller: _accountNumberController,
                labelText: '계좌번호',
                hintText: '계좌번호를 입력하세요',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '계좌번호를 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              FilledTextField(
                controller: _accountHolderController,
                labelText: '예금주',
                hintText: '예금주명을 입력하세요',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '예금주명을 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSettlementRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '정산 신청',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSettlements() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Text(
                      '최근 정산 신청',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settlement/history');
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_recentSettlements.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '정산 신청 내역이 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...List.generate(
                _recentSettlements.length,
                (index) {
                  final settlement = _recentSettlements[index];
                  return _buildSettlementItem(settlement);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementItem(SettlementResponse settlement) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberFormat('#,###').format(settlement.amount)}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(settlement.createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              settlement.status.displayName,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 관리'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettlableAmountCard(),
                    const SizedBox(height: 16),
                    _buildSettlementForm(),
                    const SizedBox(height: 16),
                    _buildRecentSettlements(),
                  ],
                ),
              ),
            ),
    );
  }
}