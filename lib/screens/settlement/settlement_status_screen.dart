import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/settlement.dart';
import '../../services/settlement_service.dart';
import '../../constants/styles.dart';

class SettlementStatusScreen extends StatefulWidget {
  final int? settlementId;

  const SettlementStatusScreen({
    super.key,
    this.settlementId,
  });

  @override
  State<SettlementStatusScreen> createState() => _SettlementStatusScreenState();
}

class _SettlementStatusScreenState extends State<SettlementStatusScreen> {
  final SettlementService _settlementService = SettlementService();
  final TextEditingController _idController = TextEditingController();
  
  SettlementResponse? _settlement;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.settlementId != null) {
      _idController.text = widget.settlementId.toString();
      _searchSettlement();
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _searchSettlement() async {
    final idText = _idController.text.trim();
    if (idText.isEmpty) {
      setState(() {
        _errorMessage = '정산 ID를 입력해 주세요.';
        _settlement = null;
      });
      return;
    }

    final settlementId = int.tryParse(idText);
    if (settlementId == null) {
      setState(() {
        _errorMessage = '올바른 정산 ID를 입력해 주세요.';
        _settlement = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settlement = await _settlementService.getSettlementStatus(settlementId);
      
      if (mounted) {
        setState(() {
          _settlement = settlement;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _settlement = null;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  '정산 ID 검색',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '정산 ID',
                      hintText: '정산 ID를 입력하세요',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    onFieldSubmitted: (_) => _searchSettlement(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchSettlement,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('검색'),
                ),
              ],
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementDetails() {
    if (_settlement == null) return const SizedBox.shrink();

    Color statusColor;
    IconData statusIcon;
    
    switch (_settlement!.status) {
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
      elevation: 2,
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
                    Icon(Icons.receipt_long, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Text(
                      '정산 상세 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _searchSettlement,
                  tooltip: '새로고침',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 상태 표시
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      _settlement!.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 정산 정보 그리드
            _buildInfoGrid(),
            
            // 메시지
            if (_settlement!.message != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          '처리 메시지',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _settlement!.message!,
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ],
            
            // 진행 상황
            const SizedBox(height: 24),
            _buildProgressTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.monetization_on,
                iconColor: Colors.green,
                title: '정산 금액',
                value: '${NumberFormat('#,###').format(_settlement!.amount)}원',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.receipt,
                iconColor: Colors.blue,
                title: '요청 ID',
                value: _settlement!.requestId,
                isMonospace: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.calendar_today,
                iconColor: Colors.purple,
                title: '신청일',
                value: DateFormat('yyyy-MM-dd\nHH:mm').format(_settlement!.createdAt),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.event,
                iconColor: Colors.orange,
                title: '예정일',
                value: _settlement!.scheduledDate != null
                    ? DateFormat('yyyy-MM-dd').format(_settlement!.scheduledDate!)
                    : '미정',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline() {
    final steps = [
      {
        'title': '정산 신청 접수',
        'date': _settlement!.createdAt,
        'completed': true,
      },
      {
        'title': '정산 검토 및 처리',
        'date': null,
        'completed': [SettlementStatus.processing, SettlementStatus.completed]
            .contains(_settlement!.status),
      },
      {
        'title': '정산 완료',
        'date': _settlement!.scheduledDate,
        'completed': _settlement!.status == SettlementStatus.completed,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '정산 진행 상황',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ...List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: step['completed'] as bool
                          ? Colors.green
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step['completed'] as bool
                          ? Icons.check
                          : Icons.circle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: step['completed'] as bool
                              ? Colors.green
                              : Colors.grey[600],
                        ),
                      ),
                      if (step['date'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(step['date'] as DateTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else if (step['completed'] as bool && index == 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          '진행 중',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 상태 조회'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchSection(),
            const SizedBox(height: 16),
            _buildSettlementDetails(),
          ],
        ),
      ),
    );
  }
}