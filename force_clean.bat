@echo off
echo Performing COMPLETE Flutter cleanup...

echo Step 1: Stopping any running Flutter processes...
taskkill /f /im flutter.exe 2>nul
taskkill /f /im dart.exe 2>nul

echo Step 2: Deleting ALL build artifacts...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
if exist .packages del .packages
if exist pubspec.lock del pubspec.lock

echo Step 3: Clearing Flutter cache...
flutter clean

echo Step 4: Clearing pub cache...
flutter pub cache clean

echo Step 5: Getting fresh dependencies...
flutter pub get

echo Step 6: Clearing web cache...
if exist web\.* del web\.*

echo Cleanup complete! Now try running:
echo flutter run -d chrome --web-port 46152
pause