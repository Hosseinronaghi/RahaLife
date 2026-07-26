import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.more)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.more))),
          ListTile(leading: const Icon(Icons.auto_awesome), title: Text(l10n.aiAssistant), onTap: () => context.push('/settings/ai')),
      ]),
    );
  }
}
