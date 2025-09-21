import 'package:json_annotation/json_annotation.dart';

part 'puzzle_mission.g.dart';

enum PuzzleType {
  numberSequence,
  patternMatch,
  colorSequence,
}

@JsonSerializable()
class PuzzleMission {
  final int id;
  final PuzzleType type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int timeLimitSeconds;

  const PuzzleMission({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.timeLimitSeconds,
  });

  factory PuzzleMission.fromJson(Map<String, dynamic> json) => _$PuzzleMissionFromJson(json);
  Map<String, dynamic> toJson() => _$PuzzleMissionToJson(this);

  factory PuzzleMission.generateRandom() {
    // 랜덤 퍼즐 생성 로직
    final random = DateTime.now().millisecondsSinceEpoch % 3;
    
    switch (random) {
      case 0:
        return _generateNumberSequence();
      case 1:
        return _generatePatternMatch();
      case 2:
        return _generateColorSequence();
      default:
        return _generateNumberSequence();
    }
  }

  static PuzzleMission _generateNumberSequence() {
    // 숫자 순서 맞추기 퍼즐
    final sequences = [
      {
        'question': '다음 숫자 순서에서 빈칸에 들어갈 숫자는?',
        'sequence': '2, 4, 6, 8, ?, 12',
        'answer': '10',
        'options': ['9', '10', '11', '12']
      },
      {
        'question': '다음 숫자 순서에서 빈칸에 들어갈 숫자는?',
        'sequence': '1, 4, 9, 16, ?, 36',
        'answer': '25',
        'options': ['20', '25', '30', '35']
      },
      {
        'question': '다음 숫자 순서에서 빈칸에 들어갈 숫자는?',
        'sequence': '1, 1, 2, 3, 5, ?, 13',
        'answer': '8',
        'options': ['6', '7', '8', '9']
      },
    ];
    
    final selected = sequences[DateTime.now().millisecondsSinceEpoch % sequences.length];
    
    return PuzzleMission(
      id: DateTime.now().millisecondsSinceEpoch,
      type: PuzzleType.numberSequence,
      question: selected['question'] as String,
      options: List<String>.from(selected['options'] as List),
      correctAnswer: selected['answer'] as String,
      timeLimitSeconds: 30,
    );
  }

  static PuzzleMission _generatePatternMatch() {
    // 패턴 매칭 퍼즐
    final patterns = [
      {
        'question': '다음 패턴에서 빈칸에 들어갈 모양은?',
        'pattern': '▲ ▼ ▲ ▼ ▲ ?',
        'answer': '▼',
        'options': ['▲', '▼', '●', '■']
      },
      {
        'question': '다음 패턴에서 빈칸에 들어갈 모양은?',
        'pattern': '● ■ ● ■ ● ?',
        'answer': '■',
        'options': ['●', '■', '▲', '▼']
      },
    ];
    
    final selected = patterns[DateTime.now().millisecondsSinceEpoch % patterns.length];
    
    return PuzzleMission(
      id: DateTime.now().millisecondsSinceEpoch,
      type: PuzzleType.patternMatch,
      question: selected['question'] as String,
      options: List<String>.from(selected['options'] as List),
      correctAnswer: selected['answer'] as String,
      timeLimitSeconds: 30,
    );
  }

  static PuzzleMission _generateColorSequence() {
    // 색상 순서 퍼즐
    final colorSequences = [
      {
        'question': '다음 색상 순서에서 빈칸에 들어갈 색은?',
        'sequence': '빨강, 파랑, 빨강, 파랑, 빨강, ?',
        'answer': '파랑',
        'options': ['빨강', '파랑', '노랑', '초록']
      },
    ];
    
    final selected = colorSequences[DateTime.now().millisecondsSinceEpoch % colorSequences.length];
    
    return PuzzleMission(
      id: DateTime.now().millisecondsSinceEpoch,
      type: PuzzleType.colorSequence,
      question: selected['question'] as String,
      options: List<String>.from(selected['options'] as List),
      correctAnswer: selected['answer'] as String,
      timeLimitSeconds: 30,
    );
  }
}
