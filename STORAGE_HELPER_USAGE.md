# StorageHelper 사용법 (Reward App)

## 개요
`StorageHelper`는 이제 `reward_common` 패키지에 통합되었습니다. 각 앱별로 데이터가 분리되어 저장됩니다.

## Import
```dart
import 'package:reward_common/reward_common.dart';
```

## Reward App에서 사용법

### 기본 사용법 (권장)
```dart
// 인증 토큰 저장 (reward_app용)
await StorageHelper.saveAuthToken(token, appType: AppType.rewardApp);

// 인증 토큰 가져오기 (reward_app용)
final token = await StorageHelper.getAuthToken(appType: AppType.rewardApp);

// 사용자 정보 저장 (reward_app용)
await StorageHelper.saveUserInfo(
  userId: 'user123',
  email: 'user@example.com',
  name: 'User Name',
  appType: AppType.rewardApp,
);

// 모든 데이터 삭제 (reward_app용만)
await StorageHelper.clearAll(appType: AppType.rewardApp);
```

### 기본값 사용법 (appType 생략 시 자동으로 rewardApp 사용)
```dart
// appType을 생략하면 자동으로 AppType.rewardApp이 사용됩니다
await StorageHelper.saveAuthToken(token);
final token = await StorageHelper.getAuthToken();

await StorageHelper.saveUserInfo(
  userId: 'user123',
  email: 'user@example.com',
  name: 'User Name',
);

await StorageHelper.clearAll();
```

## 주의사항
- Reward App의 데이터는 접두사 없이 저장됩니다 (예: `auth_token`)
- Reward Business 앱의 데이터와 분리되어 관리됩니다
- `clearAll()`을 호출해도 Business 앱의 데이터는 삭제되지 않습니다

## 스토어 관련 기능
Reward App에서는 스토어 관련 기능을 사용할 수 없습니다. 스토어 관련 기능은 Reward Business 앱 전용입니다.