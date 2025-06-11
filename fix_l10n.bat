@echo off
echo Fixing Flutter localization generation...

echo Step 1: Clean build cache...
flutter clean

echo Step 2: Get dependencies...
flutter pub get

echo Step 3: Generate localizations...
flutter gen-l10n

echo Step 4: Try building...
flutter build web --no-sound-null-safety

echo L10n fix complete!
echo Now try: flutter run -d chrome --web-port 46152
pause