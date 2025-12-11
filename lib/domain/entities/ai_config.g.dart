// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AIConfigImpl _$$AIConfigImplFromJson(Map<String, dynamic> json) =>
    _$AIConfigImpl(
      provider: $enumDecodeNullable(_$AIProviderEnumMap, json['provider']) ??
          AIProvider.gemini,
      modelName: json['modelName'] as String? ?? 'gemini-pro',
      systemPrompt:
          json['systemPrompt'] as String? ?? 'You are a helpful AI assistant.',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
    );

Map<String, dynamic> _$$AIConfigImplToJson(_$AIConfigImpl instance) =>
    <String, dynamic>{
      'provider': _$AIProviderEnumMap[instance.provider]!,
      'modelName': instance.modelName,
      'systemPrompt': instance.systemPrompt,
      'temperature': instance.temperature,
    };

const _$AIProviderEnumMap = {
  AIProvider.gemini: 'gemini',
  AIProvider.openai: 'openai',
};
