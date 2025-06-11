# Flutter 빌드 문제 해결 가이드

## 현재 상황
- **Dart 코드 레벨의 모든 컴파일 에러는 해결 완료** ✅
- Android Gradle 빌드 시스템에서 발생하는 문제들 ❌

## 주요 수정 완료 사항
1. ✅ 중복된 context extension 문제 해결
2. ✅ User 모델의 json_annotation 코드 생성 
3. ✅ ApiResponse와 User 생성자 파라미터 문제 수정
4. ✅ StorageHelper 메서드들 구현
5. ✅ AppConfig 충돌 문제 해결
6. ✅ Context extensions import 8개 파일에 추가
7. ✅ JSON 저장 문제 해결 (jsonEncode 추가)
8. ✅ AuthApi stub 구현으로 컴파일 에러 해결

## 현재 남은 문제들

### 1. Windows/WSL 경로 혼재 문제
- Windows Flutter SDK와 WSL 환경 간 경로 충돌
- 해결책: Windows 환경에서 직접 빌드 필요

### 2. Google Sign In 플러그인 D8 컴파일 문제  
- 에러: `D8: Compilation of classes io.flutter.plugins.googlesignin.Messages requires its nest mates`
- 해결 시도: minSdkVersion 상향, Play Services 업데이트, Proguard rules 추가

## 권장 해결 방법

### 방법 1: Windows에서 직접 빌드 (권장)
```cmd
# Windows Command Prompt 또는 PowerShell에서
cd E:\ws\edu-ide\edusense-ide\extensions\pearai-submodule\gui\my-mfe-project\reward\reward_app
flutter clean
flutter pub get
flutter build apk --debug
```

### 방법 2: Google Sign In 플러그인 문제 해결
1. **pubspec.yaml에서 google_sign_in 버전 다운그레이드** (이미 완료)
   ```yaml
   google_sign_in: ^6.0.0  # 6.1.6에서 다운그레이드
   ```

2. **android/app/build.gradle 설정** (이미 완료)
   - minSdkVersion 23으로 상향
   - Play Services 21.2.0으로 업데이트
   - Proguard rules 추가

3. **Gradle cache 완전 정리**
   ```cmd
   cd android
   .\gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

### 방법 3: 임시 회피 방법
Google Sign In 기능을 임시로 제거하고 빌드 확인:
```yaml
# pubspec.yaml에서 임시 주석
# google_sign_in: ^6.0.0
```

## 현재 상태 요약
- **Dart/Flutter 코드**: 모든 컴파일 에러 해결 완료 ✅
- **Android 네이티브 빌드**: Google Sign In 플러그인 문제로 실패 ❌
- **권장 해결책**: Windows 환경에서 직접 빌드

## 다음 단계
1. Windows 환경에서 `flutter build apk --debug` 실행
2. 여전히 Google Sign In 문제 발생시 버전 추가 다운그레이드 시도
3. 최종적으로는 플러그인 교체 또는 업스트림 버그 수정 대기 필요