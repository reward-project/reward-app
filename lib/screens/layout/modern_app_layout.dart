import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_extended.dart';
import 'package:reward_common/providers/auth_provider.dart';

class ModernAppLayout extends StatelessWidget {
  final Widget child;

  const ModernAppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Modern App Layout',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}