import 'package:freezed_annotation/freezed_annotation.dart';

part 'survival_entry_dto.freezed.dart';
part 'survival_entry_dto.g.dart';

@freezed
class SurvivalEntryDto with _$SurvivalEntryDto {
  const factory SurvivalEntryDto({
    required String userId,
    required String username,
    required int boardsSolved,
    required int durationSeconds,
    int? totalScore,
    required DateTime playedAt,
  }) = _SurvivalEntryDto;

  factory SurvivalEntryDto.fromJson(Map<String, dynamic> json) =>
      _$SurvivalEntryDtoFromJson(json);
}
