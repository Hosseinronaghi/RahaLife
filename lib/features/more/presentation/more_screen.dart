import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.more)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _MoreSection(
            children: [
              _MoreTile(
                icon: Icons.person_rounded,
                title: l10n.profile,
                subtitle: account?.name ?? l10n.guestMode,
                onTap: () => context.push('/profile'),
              ),
              _MoreTile(
                icon: Icons.settings_rounded,
                title: l10n.settings,
                subtitle: l10n.personalization,
                onTap: () => context.push('/settings'),
              ),
              _MoreTile(
                icon: Icons.auto_awesome_rounded,
                title: l10n.aiAssistant,
                subtitle: l10n.personalApi,
                onTap: () => context.push('/settings/ai'),
              ),
              _MoreTile(
                icon: Icons.search_rounded,
                title: l10n.globalSearch,
                subtitle: l10n.searchEverything,
                onTap: () => context.push('/search'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MoreSection(
            children: [
              _MoreTile(
                icon: Icons.cloud_sync_rounded,
                title: l10n.accountAndSync,
                subtitle: account == null ? l10n.createAccount : account.email,
                onTap: () => context.push('/account'),
              ),
              _MoreTile(
                icon: Icons.forum_rounded,
                title: l10n.messages,
                subtitle: l10n.comingSoon,
                onTap: () => context.push(
                  '/coming-soon',
                  extra: l10n.messages,
                ),
              ),
              _MoreTile(
                icon: Icons.widgets_rounded,
                title: l10n.widgets,
                subtitle: l10n.comingSoon,
                onTap: () => context.push(
                  '/coming-soon',
                  extra: l10n.widgets,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MoreSection(
            children: [
              _MoreTile(
                icon: Icons.info_outline_rounded,
                title: l10n.about,
                subtitle: '${l10n.version} ${localizeDigits('0.3.0', Localizations.localeOf(context))}',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: l10n.appName,
                  applicationVersion: localizeDigits(
                    '0.3.0',
                    Localizations.localeOf(context),
                  ),
                  applicationIcon: Icon(
                    Icons.eco_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 42,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const Divider(),
            ],
          ],
        ),
      );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}
