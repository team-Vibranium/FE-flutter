import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/puzzle_mission.dart';

final puzzleStateProvider = StateNotifierProvider<PuzzleNotifier, PuzzleState>((ref) {
  return PuzzleNotifier();
});

class PuzzleState {
  final PuzzleMission? currentMission;
  final String? selectedAnswer;
  final bool isCompleted;
  final bool isCorrect;
  final int timeRemaining;
  final bool isTimeUp;
  final String? error;

  const PuzzleState({
    this.currentMission,
    this.selectedAnswer,
    this.isCompleted = false,
    this.isCorrect = false,
    this.timeRemaining = 0,
    this.isTimeUp = false,
    this.error,
  });

  bool get isActive => currentMission != null && !isCompleted && !isTimeUp;
  bool get canSubmit => selectedAnswer != null && !isCompleted;

  PuzzleState copyWith({
    PuzzleMission? currentMission,
    String? selectedAnswer,
    bool? isCompleted,
    bool? isCorrect,
    int? timeRemaining,
    bool? isTimeUp,
    String? error,
  }) {
    return PuzzleState(
      currentMission: currentMission ?? this.currentMission,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCompleted: isCompleted ?? this.isCompleted,
      isCorrect: isCorrect ?? this.isCorrect,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isTimeUp: isTimeUp ?? this.isTimeUp,
      error: error ?? this.error,
    );
  }
}

class PuzzleNotifier extends StateNotifier<PuzzleState> {
  PuzzleNotifier() : super(const PuzzleState());

  void startNewPuzzle() {
    final mission = PuzzleMission.generateRandom();
    state = PuzzleState(
      currentMission: mission,
      timeRemaining: mission.timeLimitSeconds,
    );
    _startTimer();
  }

  void selectAnswer(String answer) {
    if (state.isActive) {
      state = state.copyWith(selectedAnswer: answer);
    }
  }

  void submitAnswer() {
    if (!state.canSubmit) return;

    final isCorrect = state.selectedAnswer == state.currentMission?.correctAnswer;
    state = state.copyWith(
      isCompleted: true,
      isCorrect: isCorrect,
    );
  }

  void _startTimer() {
    if (state.currentMission == null) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (state.timeRemaining > 0 && !state.isCompleted) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
        _startTimer();
      } else if (state.timeRemaining == 0 && !state.isCompleted) {
        state = state.copyWith(
          isTimeUp: true,
          isCompleted: true,
          isCorrect: false,
        );
      }
    });
  }

  void reset() {
    state = const PuzzleState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
