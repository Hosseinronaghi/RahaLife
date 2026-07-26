enum AiProviderType { rahaFree, openAi, gemini, customOpenAiCompatible }

class AiRequest {
  const AiRequest({required this.prompt, this.systemPrompt, this.jsonSchema});
  final String prompt;
  final String? systemPrompt;
  final Map<String, Object?>? jsonSchema;
}

class AiResponse {
  const AiResponse({required this.text, required this.provider, this.raw});
  final String text;
  final AiProviderType provider;
  final Object? raw;
}

abstract interface class AiProvider {
  AiProviderType get type;
  Future<bool> testConnection();
  Future<AiResponse> generate(AiRequest request);
  Future<List<String>> listModels();
}
