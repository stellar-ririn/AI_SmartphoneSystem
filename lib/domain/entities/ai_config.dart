import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_config.freezed.dart';
part 'ai_config.g.dart';

enum AIProvider {
  gemini,
  openai,
}

@freezed
class AIConfig with _$AIConfig {
  const factory AIConfig({
    @Default(AIProvider.gemini) AIProvider provider,
    @Default('gemini-pro') String modelName,
    @Default('You are a helpful AI assistant.') String systemPrompt,
    @Default(0.7) double temperature,
  }) = _AIConfig;

  factory AIConfig.fromJson(Map<String, dynamic> json) =>
      _$AIConfigFromJson(json);
}
