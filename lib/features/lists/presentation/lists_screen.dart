import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lists)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.lists))),
      ]),
    );
  }
}
