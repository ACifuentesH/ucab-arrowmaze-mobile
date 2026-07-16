// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survival_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SurvivalEntryDtoImpl _$$SurvivalEntryDtoImplFromJson(
  Map<String, dynamic> json,
) => _$SurvivalEntryDtoImpl(
  userId: json['userId'] as String,
  username: json['username'] as String,
  boardsSolved: (json['boardsSolved'] as num).toInt(),
  durationSeconds: (json['durationSeconds'] as num).toInt(),
  totalScore: (json['totalScore'] as num?)?.toInt(),
  playedAt: DateTime.parse(json['playedAt'] as String),
);

Map<String, dynamic> _$$SurvivalEntryDtoImplToJson(
  _$SurvivalEntryDtoImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'boardsSolved': instance.boardsSolved,
  'durationSeconds': instance.durationSeconds,
  'totalScore': instance.totalScore,
  'playedAt': instance.playedAt.toIso8601String(),
};
