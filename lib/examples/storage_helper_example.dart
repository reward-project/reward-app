import 'package:reward_common/reward_common.dart';

/// Reward App에서 StorageHelper 사용 예제
class StorageHelperExample {
  
  /// 로그인 시 사용자 정보 저장 예제 (Reward App)
  static Future<void> saveUserSession({
    required String token,
    required String refreshToken,
    required String userId,
    required String email,
    required String name,
  }) async {
    // Reward App용으로 저장 (기본값이므로 appType 생략 가능)
    await StorageHelper.saveAuthToken(token);
    await StorageHelper.saveRefreshToken(refreshToken);
    await StorageHelper.saveUserInfo(
      userId: userId,
      email: email,
      name: name,
    );
    
    print('✅ Reward App 사용자 세션 저장 완료');
  }

  /// 현재 사용자 정보 가져오기 예제 (Reward App)
  static Future<Map<String, String?>> getCurrentUserInfo() async {
    final token = await StorageHelper.getAuthToken();
    final userId = await StorageHelper.getUserId();
    final email = await StorageHelper.getUserEmail();
    final name = await StorageHelper.getUserName();

    print('📱 Reward App 사용자 정보:');
    print('  Token: ${token?.substring(0, 10)}...');
    print('  User ID: $userId');
    print('  Email: $email');
    print('  Name: $name');

    return {
      'token': token,
      'userId': userId,
      'email': email,
      'name': name,
    };
  }

  /// 로그아웃 예제 (Reward App)
  static Future<void> logout() async {
    await StorageHelper.clearAll(); // Reward App 데이터만 삭제
    print('👋 Reward App 로그아웃 완료 (Business 앱 데이터는 보존됨)');
  }

  /// 앱별 데이터 분리 테스트
  static Future<void> testDataSeparation() async {
    print('🧪 데이터 분리 테스트 시작...');
    
    // Reward App 데이터 저장
    await StorageHelper.saveAuthToken('app_token_123', appType: AppType.rewardApp);
    await StorageHelper.saveUserInfo(
      userId: 'app_user_1',
      email: 'app@example.com',
      name: 'App User',
      appType: AppType.rewardApp,
    );

    // Business 앱 데이터 저장
    await StorageHelper.saveAuthToken('business_token_456', appType: AppType.rewardBusiness);
    await StorageHelper.saveUserInfo(
      userId: 'business_user_1',
      email: 'business@example.com',
      name: 'Business User',
      appType: AppType.rewardBusiness,
    );
    await StorageHelper.saveStoreInfo(
      storeId: 'store_1',
      storeName: 'Test Store',
      appType: AppType.rewardBusiness,
    );

    // 데이터 확인
    final appToken = await StorageHelper.getAuthToken(appType: AppType.rewardApp);
    final businessToken = await StorageHelper.getAuthToken(appType: AppType.rewardBusiness);
    final appUserEmail = await StorageHelper.getUserEmail(appType: AppType.rewardApp);
    final businessUserEmail = await StorageHelper.getUserEmail(appType: AppType.rewardBusiness);
    final storeId = await StorageHelper.getStoreId(appType: AppType.rewardBusiness);

    print('🔍 저장된 데이터 확인:');
    print('  App Token: $appToken');
    print('  Business Token: $businessToken');
    print('  App User Email: $appUserEmail');
    print('  Business User Email: $businessUserEmail');
    print('  Store ID: $storeId');

    // App 데이터만 삭제 테스트
    await StorageHelper.clearAll(appType: AppType.rewardApp);
    
    final appTokenAfterClear = await StorageHelper.getAuthToken(appType: AppType.rewardApp);
    final businessTokenAfterClear = await StorageHelper.getAuthToken(appType: AppType.rewardBusiness);
    
    print('🧹 App 데이터 삭제 후:');
    print('  App Token: $appTokenAfterClear (null이어야 함)');
    print('  Business Token: $businessTokenAfterClear (보존되어야 함)');

    // 정리
    await StorageHelper.clearAll(appType: AppType.rewardBusiness);
    print('✅ 테스트 완료 및 정리');
  }
}