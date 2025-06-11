@echo off
echo Cleaning Flutter build cache...
flutter clean
echo Getting dependencies...
flutter pub get
echo Build cleanup complete!
pause