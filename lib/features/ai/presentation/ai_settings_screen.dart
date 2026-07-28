import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/openai_compatible_provider.dart';
import '../data/secure_ai_credentials.dart';
import '../domain/ai_provider.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  static const _providerKey = 'ai.provider';
  static const _baseUrlKey = 'ai.baseUrl';
  static const _modelKey = 'ai.model';

  final _credentials = SecureAiCredentials();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController(text: 'gpt-4.1-mini');
  AiProviderType _provider = AiProviderType.rahaFree;
  bool _loading = true;
  bool _testing = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final providerName = preferences.getString(_providerKey);
    final provider = AiProviderType.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => AiProviderType.rahaFree,
    );
    final key = await _credentials.readApiKey(provider.name);
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _apiKeyController.text = key ?? '';
      _baseUrlController.text = preferences.getString(_baseUrlKey) ?? '';
      _modelController.text =
          preferences.getString(_modelKey) ?? 'gpt-4.1-mini';
      _loading = false;
    });
  }

  Future<void> _changeProvider(AiProviderType provider) async {
    final key = await _credentials.readApiKey(provider.name);
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _apiKeyController.text = key ?? '';
    });
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_providerKey, _provider.name);
    await preferences.setString(_baseUrlKey, _baseUrlController.text.trim());
    await preferences.setString(_modelKey, _modelController.text.trim());
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      await _credentials.deleteApiKey(_provider.name);
    } else {
      await _credentials.saveApiKey(_provider.name, apiKey);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
    );
  }

  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context);
    if (_provider == AiProviderType.rahaFree ||
        _provider == AiProviderType.gemini) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.featureNotReady)),
      );
      return;
    }
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requiredField)),
      );
      return;
    }
    setState(() => _testing = true);
    final baseUrl = _provider == AiProviderType.openAi
        ? 'https://api.openai.com/v1'
        : _baseUrlController.text.trim();
    final provider = OpenAiCompatibleProvider(
      apiKey: apiKey,
      model: _modelController.text.trim().isEmpty
          ? 'gpt-4.1-mini'
          : _modelController.text.trim(),
      baseUrl: baseUrl,
      providerType: _provider,
    );
    final success = await provider.testConnection();
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.connectionSuccess : l10n.connectionFailed,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final personal = _provider != AiProviderType.rahaFree;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiAssistant)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<AiProviderType>(
                          initialValue: _provider,
                          decoration: InputDecoration(
                            labelText: l10n.aiAssistant,
                            prefixIcon:
                                const Icon(Icons.auto_awesome_rounded),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: AiProviderType.rahaFree,
                              child: Text('${l10n.rahaFreeAi} · ${l10n.comingSoon}'),
                            ),
                            DropdownMenuItem(
                              value: AiProviderType.openAi,
                              child: Text(l10n.openAiApi),
                            ),
                            DropdownMenuItem(
                              value: AiProviderType.gemini,
                              child: Text('${l10n.geminiApi} · ${l10n.comingSoon}'),
                            ),
                            DropdownMenuItem(
                              value: AiProviderType.customOpenAiCompatible,
                              child: Text(l10n.customOpenAi),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) _changeProvider(value);
                          },
                        ),
                        if (personal) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _apiKeyController,
                            obscureText: _obscureKey,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: l10n.apiKey,
                              prefixIcon: const Icon(Icons.key_rounded),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() => _obscureKey = !_obscureKey);
                                },
                                icon: Icon(
                                  _obscureKey
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _modelController,
                            decoration: InputDecoration(
                              labelText: l10n.model,
                              prefixIcon: const Icon(Icons.memory_rounded),
                            ),
                          ),
                        ],
                        if (_provider ==
                            AiProviderType.customOpenAiCompatible) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _baseUrlController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: l10n.baseUrl,
                              prefixIcon: const Icon(Icons.link_rounded),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.aiSubscriptionNotice)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testing ? null : _testConnection,
                        icon: _testing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering_rounded),
                        label: Text(l10n.testConnection),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(l10n.saveAiSettings),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
