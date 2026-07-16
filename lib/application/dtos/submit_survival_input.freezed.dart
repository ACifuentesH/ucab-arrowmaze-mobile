// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'submit_survival_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SubmitSurvivalInput _$SubmitSurvivalInputFromJson(Map<String, dynamic> json) {
  return _SubmitSurvivalInput.fromJson(json);
}

/// @nodoc
mixin _$SubmitSurvivalInput {
  int get boardsSolved => throw _privateConstructorUsedError;
  int get durationSeconds => throw _privateConstructorUsedError;
  int? get totalScore => throw _privateConstructorUsedError;

  /// Serializes this SubmitSurvivalInput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubmitSurvivalInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubmitSurvivalInputCopyWith<SubmitSurvivalInput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubmitSurvivalInputCopyWith<$Res> {
  factory $SubmitSurvivalInputCopyWith(
    SubmitSurvivalInput value,
    $Res Function(SubmitSurvivalInput) then,
  ) = _$SubmitSurvivalInputCopyWithImpl<$Res, SubmitSurvivalInput>;
  @useResult
  $Res call({int boardsSolved, int durationSeconds, int? totalScore});
}

/// @nodoc
class _$SubmitSurvivalInputCopyWithImpl<$Res, $Val extends SubmitSurvivalInput>
    implements $SubmitSurvivalInputCopyWith<$Res> {
  _$SubmitSurvivalInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubmitSurvivalInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? boardsSolved = null,
    Object? durationSeconds = null,
    Object? totalScore = freezed,
  }) {
    return _then(
      _value.copyWith(
            boardsSolved: null == boardsSolved
                ? _value.boardsSolved
                : boardsSolved // ignore: cast_nullable_to_non_nullable
                      as int,
            durationSeconds: null == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            totalScore: freezed == totalScore
                ? _value.totalScore
                : totalScore // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubmitSurvivalInputImplCopyWith<$Res>
    implements $SubmitSurvivalInputCopyWith<$Res> {
  factory _$$SubmitSurvivalInputImplCopyWith(
    _$SubmitSurvivalInputImpl value,
    $Res Function(_$SubmitSurvivalInputImpl) then,
  ) = __$$SubmitSurvivalInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int boardsSolved, int durationSeconds, int? totalScore});
}

/// @nodoc
class __$$SubmitSurvivalInputImplCopyWithImpl<$Res>
    extends _$SubmitSurvivalInputCopyWithImpl<$Res, _$SubmitSurvivalInputImpl>
    implements _$$SubmitSurvivalInputImplCopyWith<$Res> {
  __$$SubmitSurvivalInputImplCopyWithImpl(
    _$SubmitSurvivalInputImpl _value,
    $Res Function(_$SubmitSurvivalInputImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubmitSurvivalInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? boardsSolved = null,
    Object? durationSeconds = null,
    Object? totalScore = freezed,
  }) {
    return _then(
      _$SubmitSurvivalInputImpl(
        boardsSolved: null == boardsSolved
            ? _value.boardsSolved
            : boardsSolved // ignore: cast_nullable_to_non_nullable
                  as int,
        durationSeconds: null == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        totalScore: freezed == totalScore
            ? _value.totalScore
            : totalScore // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubmitSurvivalInputImpl implements _SubmitSurvivalInput {
  const _$SubmitSurvivalInputImpl({
    required this.boardsSolved,
    required this.durationSeconds,
    this.totalScore,
  });

  factory _$SubmitSurvivalInputImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubmitSurvivalInputImplFromJson(json);

  @override
  final int boardsSolved;
  @override
  final int durationSeconds;
  @override
  final int? totalScore;

  @override
  String toString() {
    return 'SubmitSurvivalInput(boardsSolved: $boardsSolved, durationSeconds: $durationSeconds, totalScore: $totalScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubmitSurvivalInputImpl &&
            (identical(other.boardsSolved, boardsSolved) ||
                other.boardsSolved == boardsSolved) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.totalScore, totalScore) ||
                other.totalScore == totalScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, boardsSolved, durationSeconds, totalScore);

  /// Create a copy of SubmitSurvivalInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubmitSurvivalInputImplCopyWith<_$SubmitSurvivalInputImpl> get copyWith =>
      __$$SubmitSurvivalInputImplCopyWithImpl<_$SubmitSurvivalInputImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubmitSurvivalInputImplToJson(this);
  }
}

abstract class _SubmitSurvivalInput implements SubmitSurvivalInput {
  const factory _SubmitSurvivalInput({
    required final int boardsSolved,
    required final int durationSeconds,
    final int? totalScore,
  }) = _$SubmitSurvivalInputImpl;

  factory _SubmitSurvivalInput.fromJson(Map<String, dynamic> json) =
      _$SubmitSurvivalInputImpl.fromJson;

  @override
  int get boardsSolved;
  @override
  int get durationSeconds;
  @override
  int? get totalScore;

  /// Create a copy of SubmitSurvivalInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubmitSurvivalInputImplCopyWith<_$SubmitSurvivalInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
