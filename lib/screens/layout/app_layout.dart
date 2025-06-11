import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return child;
        },
      ),
    );
  }
}