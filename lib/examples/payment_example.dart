import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../hooks/use_api.dart';
import '../api/lib/api.dart';

/// 결제 생성 예시 위젯
class PaymentExampleWidget extends HookConsumerWidget {
  const PaymentExampleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = useApi();
    final isLoading = useState(false);
    final paymentResult = useState<PaymentResponse?>(null);
    final error = useState<String?>(null);

    // 결제 생성 함수
    final createPayment = useCallback(() async {
      isLoading.value = true;
      error.value = null;
      
      try {
        final result = await api.callSafely(() => 
          api.paymentsApi.apiV1PaymentsPost(
            paymentCreateRequest: PaymentCreateRequestBuilder()
              ..amount = 10000
              ..method = PaymentMethod.creditCard
              ..description = 'Test Payment'
              ..orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}'
              ..build(),
          ),
        );
        
        if (result != null && result.data != null) {
          paymentResult.value = result.data!;
          
          // 결제 승인 처리
          await _approvePayment(api, result.data!.id!);
        }
      } catch (e) {
        error.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }, []);

    // 내 결제 목록 조회
    final myPayments = useState<List<PaymentResponse>?>(null);
    
    useEffect(() {
      api.callSafely(() => 
        api.paymentsApi.apiV1PaymentsMyGet(
          page: 0,
          size: 10,
        ),
      ).then((result) {
        if (result != null && result.data != null) {
          myPayments.value = result.data!.content;
        }
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 결제 생성 섹션
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading.value ? null : createPayment,
                      child: isLoading.value
                          ? const CircularProgressIndicator()
                          : const Text('Create Payment (10,000 KRW)'),
                    ),
                    if (error.value != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error.value!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (paymentResult.value != null) ...[
                      const SizedBox(height: 16),
                      _buildPaymentInfo(paymentResult.value!),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 내 결제 목록 섹션
            const Text(
              'My Payments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: myPayments.value == null
                  ? const Center(child: CircularProgressIndicator())
                  : myPayments.value!.isEmpty
                      ? const Center(child: Text('No payments found'))
                      : ListView.builder(
                          itemCount: myPayments.value!.length,
                          itemBuilder: (context, index) {
                            final payment = myPayments.value![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(payment.description ?? 'Payment'),
                                subtitle: Text(
                                  '${payment.amount} KRW - ${payment.status}',
                                ),
                                trailing: Text(
                                  payment.createdAt?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(PaymentResponse payment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment ID: ${payment.id}'),
          Text('Amount: ${payment.amount} KRW'),
          Text('Status: ${payment.status}'),
          Text('Method: ${payment.method}'),
          if (payment.pgTid != null) Text('PG TID: ${payment.pgTid}'),
        ],
      ),
    );
  }

  Future<void> _approvePayment(ApiHookResult api, String paymentId) async {
    try {
      await api.callSafely(() => 
        api.paymentsApi.apiV1PaymentsApprovePost(
          paymentApproveRequest: PaymentApproveRequestBuilder()
            ..paymentId = paymentId
            ..pgToken = 'test-pg-token'
            ..build(),
        ),
      );
    } catch (e) {
      print('Payment approval error: $e');
    }
  }
}

/// 리워드 포인트 예시 위젯
class RewardExampleWidget extends HookConsumerWidget {
  const RewardExampleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = useApi();
    final balance = useState<RewardBalance?>(null);
    final transactions = useState<List<RewardTransaction>?>(null);
    
    // 리워드 잔액 조회
    useEffect(() {
      api.callSafely(() => 
        api.rewardsApi.apiV1RewardsBalanceGet(),
      ).then((result) {
        if (result != null && result.data != null) {
          balance.value = result.data!;
        }
      });
      
      // 리워드 거래 내역 조회
      api.callSafely(() => 
        api.rewardsApi.apiV1RewardsHistoryGet(
          page: 0,
          size: 20,
        ),
      ).then((result) {
        if (result != null && result.data != null) {
          transactions.value = result.data!.content;
        }
      });
      
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Points'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 포인트 잔액 카드
            if (balance.value != null)
              Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'My Reward Points',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${balance.value!.totalPoints} P',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Available'),
                              Text(
                                '${balance.value!.availablePoints} P',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Pending'),
                              Text(
                                '${balance.value!.pendingPoints} P',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (balance.value!.expiringPoints! > 0)
                            Column(
                              children: [
                                const Text('Expiring Soon'),
                                Text(
                                  '${balance.value!.expiringPoints} P',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // 거래 내역
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: transactions.value == null
                  ? const Center(child: CircularProgressIndicator())
                  : transactions.value!.isEmpty
                      ? const Center(child: Text('No transactions yet'))
                      : ListView.builder(
                          itemCount: transactions.value!.length,
                          itemBuilder: (context, index) {
                            final tx = transactions.value![index];
                            final isEarned = tx.type == TransactionType.earned;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isEarned 
                                    ? Colors.green[100] 
                                    : Colors.red[100],
                                child: Icon(
                                  isEarned 
                                      ? Icons.add 
                                      : Icons.remove,
                                  color: isEarned 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                              ),
                              title: Text(tx.description ?? 'Transaction'),
                              subtitle: Text(
                                tx.createdAt?.toString() ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '${isEarned ? '+' : '-'}${tx.points} P',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isEarned 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}