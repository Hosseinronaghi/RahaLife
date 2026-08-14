import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../home/presentation/quick_add_sheet.dart';

class QuickAddLaunchScreen extends StatefulWidget {
  const QuickAddLaunchScreen({super.key});

  @override
  State<QuickAddLaunchScreen> createState() => _QuickAddLaunchScreenState();
}

class _QuickAddLaunchScreenState extends State<QuickAddLaunchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showQuickAdd(context);
      if (!mounted) return;
      context.go('/today');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
