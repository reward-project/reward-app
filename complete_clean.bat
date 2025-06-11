@echo off
echo Performing complete Flutter cleanup...

echo Deleting build directories...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool

echo Deleting pubspec.lock...
if exist pubspec.lock del pubspec.lock

echo Running flutter clean...
flutter clean

echo Getting dependencies...
flutter pub get

echo Cleanup complete! You can now run flutter.
pause