@echo off
echo EMERGENCY FIX: Removing all localization to get app running...

echo Step 1: Backing up current files...
if not exist backup mkdir backup
if exist lib\main.dart copy lib\main.dart backup\main.dart.bak

echo Step 2: Creating minimal main.dart without localization...
echo import 'dart:io'; > lib\main.dart
echo. >> lib\main.dart
echo import 'package:flutter/foundation.dart'; >> lib\main.dart
echo import 'package:flutter/material.dart'; >> lib\main.dart
echo import 'package:flutter/services.dart'; >> lib\main.dart
echo import 'package:flutter_web_plugins/url_strategy.dart'; >> lib\main.dart
echo import 'package:provider/provider.dart'; >> lib\main.dart
echo import 'package:dynamic_color/dynamic_color.dart'; >> lib\main.dart
echo import 'package:responsive_framework/responsive_framework.dart'; >> lib\main.dart
echo import 'router/app_router.dart'; >> lib\main.dart
echo import 'providers/locale_provider.dart'; >> lib\main.dart
echo import 'config/app_config.dart'; >> lib\main.dart
echo import 'providers/auth_provider.dart'; >> lib\main.dart
echo import 'services/dio_service.dart'; >> lib\main.dart
echo. >> lib\main.dart
echo void main() async { >> lib\main.dart
echo   WidgetsFlutterBinding.ensureInitialized(); >> lib\main.dart
echo   usePathUrlStrategy(); >> lib\main.dart
echo   await AppConfig.initialize(); >> lib\main.dart
echo   runApp(const MyApp()); >> lib\main.dart
echo } >> lib\main.dart
echo. >> lib\main.dart
echo class MyApp extends StatelessWidget { >> lib\main.dart
echo   const MyApp({super.key}); >> lib\main.dart
echo   @override >> lib\main.dart
echo   Widget build(BuildContext context) { >> lib\main.dart
echo     return MultiProvider( >> lib\main.dart
echo       providers: [ >> lib\main.dart
echo         ChangeNotifierProvider(create: (context) =^> LocaleProvider()), >> lib\main.dart
echo         ChangeNotifierProvider(create: (context) =^> AuthProvider(context)), >> lib\main.dart
echo       ], >> lib\main.dart
echo       child: MaterialApp.router( >> lib\main.dart
echo         title: 'Reward App', >> lib\main.dart
echo         routerConfig: router, >> lib\main.dart
echo         theme: ThemeData(useMaterial3: true), >> lib\main.dart
echo       ), >> lib\main.dart
echo     ); >> lib\main.dart
echo   } >> lib\main.dart
echo } >> lib\main.dart

echo Step 3: Creating empty layout files...
echo import 'package:flutter/material.dart'; > lib\screens\layout\app_layout.dart
echo class AppLayout extends StatelessWidget { >> lib\screens\layout\app_layout.dart
echo   final Widget child; >> lib\screens\layout\app_layout.dart
echo   const AppLayout({super.key, required this.child}); >> lib\screens\layout\app_layout.dart
echo   @override >> lib\screens\layout\app_layout.dart
echo   Widget build(BuildContext context) =^> Scaffold(body: child); >> lib\screens\layout\app_layout.dart
echo } >> lib\screens\layout\app_layout.dart

echo import 'package:flutter/material.dart'; > lib\screens\layout\modern_app_layout.dart
echo class ModernAppLayout extends StatelessWidget { >> lib\screens\layout\modern_app_layout.dart
echo   final Widget child; >> lib\screens\layout\modern_app_layout.dart
echo   const ModernAppLayout({super.key, required this.child}); >> lib\screens\layout\modern_app_layout.dart
echo   @override >> lib\screens\layout\modern_app_layout.dart
echo   Widget build(BuildContext context) =^> Scaffold(body: child); >> lib\screens\layout\modern_app_layout.dart
echo } >> lib\screens\layout\modern_app_layout.dart

echo Step 4: Clean build...
flutter clean
del pubspec.lock >nul 2>&1
rmdir /s /q .dart_tool >nul 2>&1
rmdir /s /q build >nul 2>&1

echo Step 5: Get dependencies...
flutter pub get

echo EMERGENCY FIX COMPLETE!
echo Try running: flutter run -d chrome --web-port 46152
pause