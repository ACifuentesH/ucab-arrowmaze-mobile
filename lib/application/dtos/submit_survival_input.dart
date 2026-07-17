import 'package:freezed_annotation/freezed_annotation.dart';

part 'submit_survival_input.freezed.dart';
part 'submit_survival_input.g.dart';

@freezed
class SubmitSurvivalInput with _$SubmitSurvivalInput {
  const factory SubmitSurvivalInput({
    required int boardsSolved,
    required int durationSeconds,
    int? totalScore,
  }) = _SubmitSurvivalInput;

  factory SubmitSurvivalInput.fromJson(Map<String, dynamic> json) =>
      _$SubmitSurvivalInputFromJson(json);
}
