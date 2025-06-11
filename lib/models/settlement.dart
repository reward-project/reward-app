class SettlementRequest {
  final String periodStartDate;
  final String periodEndDate;
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  SettlementRequest({
    required this.periodStartDate,
    required this.periodEndDate,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  Map<String, dynamic> toJson() {
    return {
      'periodStartDate': periodStartDate,
      'periodEndDate': periodEndDate,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    };
  }
}

class SettlementResponse {
  final int id;
  final String requestId;
  final String recipientId;
  final double amount;
  final SettlementStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? scheduledDate;

  SettlementResponse({
    required this.id,
    required this.requestId,
    required this.recipientId,
    required this.amount,
    required this.status,
    this.message,
    required this.createdAt,
    this.scheduledDate,
  });

  factory SettlementResponse.fromJson(Map<String, dynamic> json) {
    return SettlementResponse(
      id: json['id'],
      requestId: json['requestId'],
      recipientId: json['recipientId'],
      amount: json['amount'].toDouble(),
      status: SettlementStatus.fromString(json['status']),
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      scheduledDate: json['scheduledDate'] != null 
          ? DateTime.parse(json['scheduledDate']) 
          : null,
    );
  }
}

class SettlableAmountResponse {
  final double amount;
  final String currency;

  SettlableAmountResponse({
    required this.amount,
    required this.currency,
  });

  factory SettlableAmountResponse.fromJson(Map<String, dynamic> json) {
    return SettlableAmountResponse(
      amount: json['amount'].toDouble(),
      currency: json['currency'],
    );
  }
}

class RewardHistoryResponse {
  final int id;
  final int userId;
  final String rewardType;
  final double amount;
  final String description;
  final RewardStatus status;
  final int? settlementId;
  final DateTime createdAt;
  final DateTime? settlementDate;

  RewardHistoryResponse({
    required this.id,
    required this.userId,
    required this.rewardType,
    required this.amount,
    required this.description,
    required this.status,
    this.settlementId,
    required this.createdAt,
    this.settlementDate,
  });

  factory RewardHistoryResponse.fromJson(Map<String, dynamic> json) {
    return RewardHistoryResponse(
      id: json['id'],
      userId: json['userId'],
      rewardType: json['rewardType'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      status: RewardStatus.fromString(json['status']),
      settlementId: json['settlementId'],
      createdAt: DateTime.parse(json['createdAt']),
      settlementDate: json['settlementDate'] != null 
          ? DateTime.parse(json['settlementDate']) 
          : null,
    );
  }
}

class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResponse<T>(
      content: (json['content'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
      number: json['number'],
      size: json['size'],
      first: json['first'],
      last: json['last'],
    );
  }
}

enum SettlementStatus {
  pending,
  processing,
  completed,
  cancelled,
  failed;

  static SettlementStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return SettlementStatus.pending;
      case 'PROCESSING':
        return SettlementStatus.processing;
      case 'COMPLETED':
        return SettlementStatus.completed;
      case 'CANCELLED':
        return SettlementStatus.cancelled;
      case 'FAILED':
        return SettlementStatus.failed;
      default:
        return SettlementStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case SettlementStatus.pending:
        return '정산 대기';
      case SettlementStatus.processing:
        return '정산 처리중';
      case SettlementStatus.completed:
        return '정산 완료';
      case SettlementStatus.cancelled:
        return '정산 취소';
      case SettlementStatus.failed:
        return '정산 실패';
    }
  }
}

enum RewardStatus {
  pending,
  processing,
  completed,
  hold,
  cancelled,
  failed;

  static RewardStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return RewardStatus.pending;
      case 'PROCESSING':
        return RewardStatus.processing;
      case 'COMPLETED':
        return RewardStatus.completed;
      case 'HOLD':
        return RewardStatus.hold;
      case 'CANCELLED':
        return RewardStatus.cancelled;
      case 'FAILED':
        return RewardStatus.failed;
      default:
        return RewardStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case RewardStatus.pending:
        return '정산대기';
      case RewardStatus.processing:
        return '정산중';
      case RewardStatus.completed:
        return '정산완료';
      case RewardStatus.hold:
        return '보류';
      case RewardStatus.cancelled:
        return '취소';
      case RewardStatus.failed:
        return '실패';
    }
  }
}