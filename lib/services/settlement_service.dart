import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/settlement.dart';
import 'dio_service.dart';

class SettlementService {
  final DioService _dioService = DioService();

  // 정산 신청
  Future<SettlementResponse> requestSettlement(
    int userId,
    SettlementRequest request,
  ) async {
    try {
      final response = await _dioService.post(
        '${AppConfig.rewardApiUrl}/settlements',
        queryParameters: {'userId': userId},
        data: request.toJson(),
      );

      return SettlementResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 정산 상태 조회
  Future<SettlementResponse> getSettlementStatus(int settlementId) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.rewardApiUrl}/settlements/$settlementId',
      );

      return SettlementResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 정산 가능 금액 조회
  Future<SettlableAmountResponse> getSettlableAmount(int userId) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.rewardApiUrl}/settlements/settable-amount',
        queryParameters: {'userId': userId},
      );

      return SettlableAmountResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 리워드 내역 조회 (페이지네이션)
  Future<PageResponse<RewardHistoryResponse>> getRewardHistory(
    int userId, {
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.rewardApiUrl}/settlements/rewards',
        queryParameters: {
          'userId': userId,
          'page': page,
          'size': size,
          if (sort != null) 'sort': sort,
        },
      );

      return PageResponse.fromJson(
        response.data,
        (json) => RewardHistoryResponse.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 정산 신청 내역 조회
  Future<List<SettlementResponse>> getMySettlements(int userId) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.rewardApiUrl}/settlements/my-settlements',
        queryParameters: {'userId': userId},
      );

      return (response.data as List)
          .map((item) => SettlementResponse.fromJson(item))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 에러 핸들링
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '네트워크 연결 시간이 초과되었습니다.';
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 401) {
            return '인증이 필요합니다. 다시 로그인해 주세요.';
          } else if (error.response?.statusCode == 403) {
            return '권한이 없습니다.';
          } else if (error.response?.statusCode == 404) {
            return '요청한 데이터를 찾을 수 없습니다.';
          } else if (error.response?.statusCode == 500) {
            return '서버 오류가 발생했습니다.';
          }
          return '알 수 없는 오류가 발생했습니다. (${error.response?.statusCode})';
        case DioExceptionType.cancel:
          return '요청이 취소되었습니다.';
        case DioExceptionType.connectionError:
          return '네트워크 연결에 실패했습니다.';
        default:
          return '네트워크 오류가 발생했습니다.';
      }
    }
    return error.toString();
  }
}