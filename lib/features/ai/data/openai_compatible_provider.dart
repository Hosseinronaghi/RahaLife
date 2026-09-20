import 'package:dio/dio.dart';

import '../domain/ai_provider.dart';

class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({
    required this.apiKey,
    required this.model,
    this.baseUrl = 'https://api.openai.com/v1',
    this.providerType = AiProviderType.openAi,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 60),
               sendTimeout: const Duration(seconds: 30),
               followRedirects: false,
             ),
           );

  Uri endpoint(String path) {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'A valid HTTPS API address without credentials or query is required.',
      );
    }
    return uri.replace(
      path: '${uri.path.replaceFirst(RegExp(r"/+$"), "")}/$path',
    );
  }

  final String apiKey;
  final String model;
  final String baseUrl;
  final AiProviderType providerType;
  final Dio _dio;

  @override
  AiProviderType get type => providerType;

  Options get _options => Options(
    followRedirects: false,
    headers: {'Authorization': 'Bearer $apiKey'},
  );

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      endpoint('chat/completions').toString(),
      options: _options,
      data: {
        'model': model,
        'messages': [
          if (request.systemPrompt != null)
            {'role': 'system', 'content': request.systemPrompt},
          {'role': 'user', 'content': request.prompt},
        ],
        'temperature': 0.2,
      },
    );
    final data = response.data ?? const {};
    final choices = data['choices'] as List<dynamic>? ?? const [];
    final first = choices.isEmpty
        ? null
        : choices.first as Map<String, dynamic>?;
    final message = first?['message'] as Map<String, dynamic>?;
    final text = message?['content']?.toString() ?? '';
    return AiResponse(text: text, provider: type, raw: data);
  }

  @override
  Future<List<String>> listModels() async {
    final response = await _dio.get<Map<String, Object?>>(
      endpoint('models').toString(),
      options: _options,
    );
    final list = response.data?['data'] as List<dynamic>? ?? const [];
    return list
        .map((e) => (e as Map<String, dynamic>)['id'].toString())
        .toList();
  }

  @override
  Future<bool> testConnection() async {
    try {
      await listModels();
      return true;
    } catch (_) {
      return false;
    }
  }
}
