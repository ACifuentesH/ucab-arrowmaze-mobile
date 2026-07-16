enum SurvivalPhase { initial, running, ended, submitting, success, error }

class SurvivalState {
  final int timeLeft;
  final int boardsCleared;
  final SurvivalPhase phase;
  final String? errorMessage;

  const SurvivalState({
    required this.timeLeft,
    required this.boardsCleared,
    required this.phase,
    this.errorMessage,
  });

  const SurvivalState.initial() : this(
        timeLeft: 0,
        boardsCleared: 0,
        phase: SurvivalPhase.initial,
        errorMessage: null,
      );

  SurvivalState copyWith({
    int? timeLeft,
    int? boardsCleared,
    SurvivalPhase? phase,
    String? errorMessage,
  }) {
    return SurvivalState(
      timeLeft: timeLeft ?? this.timeLeft,
      boardsCleared: boardsCleared ?? this.boardsCleared,
      phase: phase ?? this.phase,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

