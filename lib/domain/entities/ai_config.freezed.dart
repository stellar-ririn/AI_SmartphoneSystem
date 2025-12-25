// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AIConfig _$AIConfigFromJson(Map<String, dynamic> json) {
  return _AIConfig.fromJson(json);
}

/// @nodoc
mixin _$AIConfig {
  AIProvider get provider => throw _privateConstructorUsedError;
  String get modelName => throw _privateConstructorUsedError;
  String get systemPrompt => throw _privateConstructorUsedError;
  double get temperature => throw _privateConstructorUsedError;

  /// Serializes this AIConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AIConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AIConfigCopyWith<AIConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIConfigCopyWith<$Res> {
  factory $AIConfigCopyWith(AIConfig value, $Res Function(AIConfig) then) =
      _$AIConfigCopyWithImpl<$Res, AIConfig>;
  @useResult
  $Res call(
      {AIProvider provider,
      String modelName,
      String systemPrompt,
      double temperature});
}

/// @nodoc
class _$AIConfigCopyWithImpl<$Res, $Val extends AIConfig>
    implements $AIConfigCopyWith<$Res> {
  _$AIConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AIConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? provider = null,
    Object? modelName = null,
    Object? systemPrompt = null,
    Object? temperature = null,
  }) {
    return _then(_value.copyWith(
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as AIProvider,
      modelName: null == modelName
          ? _value.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String,
      systemPrompt: null == systemPrompt
          ? _value.systemPrompt
          : systemPrompt // ignore: cast_nullable_to_non_nullable
              as String,
      temperature: null == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AIConfigImplCopyWith<$Res>
    implements $AIConfigCopyWith<$Res> {
  factory _$$AIConfigImplCopyWith(
          _$AIConfigImpl value, $Res Function(_$AIConfigImpl) then) =
      __$$AIConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AIProvider provider,
      String modelName,
      String systemPrompt,
      double temperature});
}

/// @nodoc
class __$$AIConfigImplCopyWithImpl<$Res>
    extends _$AIConfigCopyWithImpl<$Res, _$AIConfigImpl>
    implements _$$AIConfigImplCopyWith<$Res> {
  __$$AIConfigImplCopyWithImpl(
      _$AIConfigImpl _value, $Res Function(_$AIConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of AIConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? provider = null,
    Object? modelName = null,
    Object? systemPrompt = null,
    Object? temperature = null,
  }) {
    return _then(_$AIConfigImpl(
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as AIProvider,
      modelName: null == modelName
          ? _value.modelName
          : modelName // ignore: cast_nullable_to_non_nullable
              as String,
      systemPrompt: null == systemPrompt
          ? _value.systemPrompt
          : systemPrompt // ignore: cast_nullable_to_non_nullable
              as String,
      temperature: null == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AIConfigImpl implements _AIConfig {
  const _$AIConfigImpl(
      {this.provider = AIProvider.gemini,
      this.modelName = 'gemini-pro',
      this.systemPrompt = 'You are a helpful AI assistant.',
      this.temperature = 0.7});

  factory _$AIConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIConfigImplFromJson(json);

  @override
  @JsonKey()
  final AIProvider provider;
  @override
  @JsonKey()
  final String modelName;
  @override
  @JsonKey()
  final String systemPrompt;
  @override
  @JsonKey()
  final double temperature;

  @override
  String toString() {
    return 'AIConfig(provider: $provider, modelName: $modelName, systemPrompt: $systemPrompt, temperature: $temperature)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIConfigImpl &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.modelName, modelName) ||
                other.modelName == modelName) &&
            (identical(other.systemPrompt, systemPrompt) ||
                other.systemPrompt == systemPrompt) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, provider, modelName, systemPrompt, temperature);

  /// Create a copy of AIConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIConfigImplCopyWith<_$AIConfigImpl> get copyWith =>
      __$$AIConfigImplCopyWithImpl<_$AIConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIConfigImplToJson(
      this,
    );
  }
}

abstract class _AIConfig implements AIConfig {
  const factory _AIConfig(
      {final AIProvider provider,
      final String modelName,
      final String systemPrompt,
      final double temperature}) = _$AIConfigImpl;

  factory _AIConfig.fromJson(Map<String, dynamic> json) =
      _$AIConfigImpl.fromJson;

  @override
  AIProvider get provider;
  @override
  String get modelName;
  @override
  String get systemPrompt;
  @override
  double get temperature;

  /// Create a copy of AIConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIConfigImplCopyWith<_$AIConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
