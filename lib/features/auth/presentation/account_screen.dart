import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'auth_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    if (state.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return state.signedIn ? const _SignedInAccount() : const _AuthForms();
  }
}

class _SignedInAccount extends ConsumerWidget {
  const _SignedInAccount();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                CircleAvatar(radius: 44, child: Text(user.name.characters.first, style: Theme.of(context).textTheme.headlineMedium)),
                const SizedBox(height: 14),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(user.email),
                const SizedBox(height: 16),
                Chip(avatar: const Icon(Icons.offline_bolt_rounded, size: 18), label: Text(l10n.localAccount)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(children: [
              ListTile(leading: const Icon(Icons.cloud_off_rounded), title: Text(l10n.syncStatus), subtitle: Text(l10n.syncNextVersion)),
              const Divider(),
              ListTile(leading: const Icon(Icons.devices_rounded), title: Text(l10n.multiDevice), subtitle: Text(l10n.syncNextVersion)),
            ]),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: () => ref.read(authProvider.notifier).signOut(), icon: const Icon(Icons.logout_rounded), label: Text(l10n.signOut)),
        ],
      ),
    );
  }
}

class _AuthForms extends StatefulWidget {
  const _AuthForms();
  @override
  State<_AuthForms> createState() => _AuthFormsState();
}

class _AuthFormsState extends State<_AuthForms> {
  bool signUp = true;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SegmentedButton<bool>(segments: [ButtonSegment(value: true, label: Text(l10n.createAccount), icon: const Icon(Icons.person_add_rounded)), ButtonSegment(value: false, label: Text(l10n.signIn), icon: const Icon(Icons.login_rounded))], selected: {signUp}, onSelectionChanged: (value) => setState(() => signUp = value.first)),
                  const SizedBox(height: 22),
                  _CredentialsForm(signUp: signUp),
                  const SizedBox(height: 16),
                  Text(l10n.localAccountNotice, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredentialsForm extends ConsumerStatefulWidget {
  const _CredentialsForm({required this.signUp});
  final bool signUp;
  @override
  ConsumerState<_CredentialsForm> createState() => _CredentialsFormState();
}

class _CredentialsFormState extends ConsumerState<_CredentialsForm> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }

  String _errorLabel(AppLocalizations l10n, String? code) => switch (code) {
    'weakPassword' => l10n.weakPassword,
    'accountExists' => l10n.accountExists,
    'accountNotFound' => l10n.accountNotFound,
    'invalidCredentials' => l10n.invalidCredentials,
    _ => '',
  };

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(authProvider.notifier);
    final ok = widget.signUp
        ? await notifier.signUp(name: name.text, email: email.text, password: password.text)
        : await notifier.signIn(email: email.text, password: password.text);
    if (!ok && mounted) {
      final error = ref.read(authProvider).errorCode;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorLabel(AppLocalizations.of(context), error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loading = ref.watch(authProvider).loading;
    return Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.signUp) ...[
          TextFormField(controller: name, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: l10n.fullName), validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null),
          const SizedBox(height: 12),
        ],
        TextFormField(controller: email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: l10n.email), validator: (value) => value == null || !value.contains('@') ? l10n.invalidEmail : null),
        const SizedBox(height: 12),
        TextFormField(controller: password, obscureText: obscure, onFieldSubmitted: (_) => submit(), decoration: InputDecoration(labelText: l10n.password, suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded))), validator: (value) => value == null || value.length < 8 ? l10n.weakPassword : null),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: loading ? null : submit, icon: Icon(widget.signUp ? Icons.person_add_rounded : Icons.login_rounded), label: Text(widget.signUp ? l10n.createAccount : l10n.signIn)),
      ]),
    );
  }
}
