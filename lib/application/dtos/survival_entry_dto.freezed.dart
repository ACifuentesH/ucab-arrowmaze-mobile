// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'survival_entry_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SurvivalEntryDto _$SurvivalEntryDtoFromJson(Map<String, dynamic> json) {
  return _SurvivalEntryDto.fromJson(json);
}

/// @nodoc
mixin _$SurvivalEntryDto {
  String get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  int get boardsSolved => throw _privateConstructorUsedError;
  int get durationSeconds => throw _privateConstructorUsedError;
  int? get totalScore => throw _privateConstructorUsedError;
  DateTime get playedAt => throw _privateConstructorUsedError;

  /// Serializes this SurvivalEntryDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SurvivalEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SurvivalEntryDtoCopyWith<SurvivalEntryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SurvivalEntryDtoCopyWith<$Res> {
  factory $SurvivalEntryDtoCopyWith(
    SurvivalEntryDto value,
    $Res Function(SurvivalEntryDto) then,
  ) = _$SurvivalEntryDtoCopyWithImpl<$Res, SurvivalEntryDto>;
  @useResult
  $Res call({
    String userId,
    String username,
    int boardsSolved,
    int durationSeconds,
    int? totalScore,
    DateTime playedAt,
  });
}

/// @nodoc
class _$SurvivalEntryDtoCopyWithImpl<$Res, $Val extends SurvivalEntryDto>
    implements $SurvivalEntryDtoCopyWith<$Res> {
  _$SurvivalEntryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SurvivalEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? boardsSolved = null,
    Object? durationSeconds = null,
    Object? totalScore = freezed,
    Object? playedAt = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
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
            playedAt: null == playedAt
                ? _value.playedAt
                : playedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SurvivalEntryDtoImplCopyWith<$Res>
    implements $SurvivalEntryDtoCopyWith<$Res> {
  factory _$$SurvivalEntryDtoImplCopyWith(
    _$SurvivalEntryDtoImpl value,
    $Res Function(_$SurvivalEntryDtoImpl) then,
  ) = __$$SurvivalEntryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String username,
    int boardsSolved,
    int durationSeconds,
    int? totalScore,
    DateTime playedAt,
  });
}

/// @nodoc
class __$$SurvivalEntryDtoImplCopyWithImpl<$Res>
    extends _$SurvivalEntryDtoCopyWithImpl<$Res, _$SurvivalEntryDtoImpl>
    implements _$$SurvivalEntryDtoImplCopyWith<$Res> {
  __$$SurvivalEntryDtoImplCopyWithImpl(
    _$SurvivalEntryDtoImpl _value,
    $Res Function(_$SurvivalEntryDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SurvivalEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? boardsSolved = null,
    Object? durationSeconds = null,
    Object? totalScore = freezed,
    Object? playedAt = null,
  }) {
    return _then(
      _$SurvivalEntryDtoImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
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
        playedAt: null == playedAt
            ? _value.playedAt
            : playedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SurvivalEntryDtoImpl implements _SurvivalEntryDto {
  const _$SurvivalEntryDtoImpl({
    required this.userId,
    required this.username,
    required this.boardsSolved,
    required this.durationSeconds,
    this.totalScore,
    required this.playedAt,
  });

  factory _$SurvivalEntryDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SurvivalEntryDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final String username;
  @override
  final int boardsSolved;
  @override
  final int durationSeconds;
  @override
  final int? totalScore;
  @override
  final DateTime playedAt;

  @override
  String toString() {
    return 'SurvivalEntryDto(userId: $userId, username: $username, boardsSolved: $boardsSolved, durationSeconds: $durationSeconds, totalScore: $totalScore, playedAt: $playedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SurvivalEntryDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.boardsSolved, boardsSolved) ||
                other.boardsSolved == boardsSolved) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.totalScore, totalScore) ||
                other.totalScore == totalScore) &&
            (identical(other.playedAt, playedAt) ||
                other.playedAt == playedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    username,
    boardsSolved,
    durationSeconds,
    totalScore,
    playedAt,
  );

  /// Create a copy of SurvivalEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SurvivalEntryDtoImplCopyWith<_$SurvivalEntryDtoImpl> get copyWith =>
      __$$SurvivalEntryDtoImplCopyWithImpl<_$SurvivalEntryDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SurvivalEntryDtoImplToJson(this);
  }
}

abstract class _SurvivalEntryDto implements SurvivalEntryDto {
  const factory _SurvivalEntryDto({
    required final String userId,
    required final String username,
    required final int boardsSolved,
    required final int durationSeconds,
    final int? totalScore,
    required final DateTime playedAt,
  }) = _$SurvivalEntryDtoImpl;

  factory _SurvivalEntryDto.fromJson(Map<String, dynamic> json) =
      _$SurvivalEntryDtoImpl.fromJson;

  @override
  String get userId;
  @override
  String get username;
  @override
  int get boardsSolved;
  @override
  int get durationSeconds;
  @override
  int? get totalScore;
  @override
  DateTime get playedAt;

  /// Create a copy of SurvivalEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SurvivalEntryDtoImplCopyWith<_$SurvivalEntryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
