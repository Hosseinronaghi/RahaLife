import '../domain/ai_provider.dart';

class AiConfig {
  const AiConfig({
    this.enabled = false,
    this.provider = AiProviderType.rahaFree,
    this.model = 'auto',
    this.baseUrl,
  });
  final bool enabled;
  final AiProviderType provider;
  final String model;
  final String? baseUrl;
}
