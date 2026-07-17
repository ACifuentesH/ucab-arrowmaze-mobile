// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_survival_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubmitSurvivalInputImpl _$$SubmitSurvivalInputImplFromJson(
  Map<String, dynamic> json,
) => _$SubmitSurvivalInputImpl(
  boardsSolved: (json['boardsSolved'] as num).toInt(),
  durationSeconds: (json['durationSeconds'] as num).toInt(),
  totalScore: (json['totalScore'] as num?)?.toInt(),
);

Map<String, dynamic> _$$SubmitSurvivalInputImplToJson(
  _$SubmitSurvivalInputImpl instance,
) => <String, dynamic>{
  'boardsSolved': instance.boardsSolved,
  'durationSeconds': instance.durationSeconds,
  'totalScore': instance.totalScore,
};
