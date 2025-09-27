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
  const PuzzleMission({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
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
        'question': '다음 숫자 수열에서 빈칸(?)에 들어갈 숫자를 찾으세요',
        'sequence': '2, 4, 6, 8, ?, 12',
        'hint': '💡 힌트: 2씩 증가하는 짝수들',
        'answer': '10',
        'options': ['9', '10', '11', '12']
      },
      {
        'question': '다음 숫자 수열에서 빈칸(?)에 들어갈 숫자를 찾으세요',
        'sequence': '1, 4, 9, 16, ?, 36',
        'hint': '💡 힌트: 각 숫자를 제곱한 값들 (1², 2², 3², ...)',
        'answer': '25',
        'options': ['20', '25', '30', '35']
      },
      {
        'question': '다음 숫자 수열에서 빈칸(?)에 들어갈 숫자를 찾으세요',
        'sequence': '1, 1, 2, 3, 5, ?, 13',
        'hint': '💡 힌트: 앞의 두 숫자를 더한 값 (피보나치 수열)',
        'answer': '8',
        'options': ['6', '7', '8', '9']
      },
      {
        'question': '다음 숫자 수열에서 빈칸(?)에 들어갈 숫자를 찾으세요',
        'sequence': '5, 10, 15, ?, 25',
        'hint': '💡 힌트: 5씩 증가하는 수열',
        'answer': '20',
        'options': ['18', '19', '20', '21']
      },
    ];
    
    final selected = sequences[DateTime.now().millisecondsSinceEpoch % sequences.length];
    
    return PuzzleMission(
      id: DateTime.now().millisecondsSinceEpoch,
      type: PuzzleType.numberSequence,
      question: '${selected['question']}\n\n📊 ${selected['sequence']}\n\n${selected['hint']}',
      options: List<String>.from(selected['options'] as List),
      correctAnswer: selected['answer'] as String,
    );
  }

  static PuzzleMission _generatePatternMatch() {
    // 패턴 매칭 퍼즐
    final patterns = [
      {
        'question': '다음 도형 패턴에서 빈칸(?)에 들어갈 모양을 찾으세요',
        'pattern': '▲ ▼ ▲ ▼ ▲ ?',
        'hint': '💡 힌트: 위쪽 삼각형과 아래쪽 삼각형이 번갈아 나타남',
        'answer': '▼',
        'options': ['▲', '▼', '●', '■']
      },
      {
        'question': '다음 도형 패턴에서 빈칸(?)에 들어갈 모양을 찾으세요',
        'pattern': '● ■ ● ■ ● ?',
        'hint': '💡 힌트: 원과 사각형이 번갈아 나타남',
        'answer': '■',
        'options': ['●', '■', '▲', '▼']
      },
      {
        'question': '다음 도형 패턴에서 빈칸(?)에 들어갈 모양을 찾으세요',
        'pattern': '★ ☆ ★ ☆ ★ ?',
        'hint': '💡 힌트: 꽉 찬 별과 빈 별이 번갈아 나타남',
        'answer': '☆',
        'options': ['★', '☆', '●', '■']
      },
      {
        'question': '다음 도형 패턴에서 빈칸(?)에 들어갈 모양을 찾으세요',
        'pattern': '◆ ◇ ◆ ◇ ?',
        'hint': '💡 힌트: 꽉 찬 다이아몬드와 빈 다이아몬드가 번갈아 나타남',
        'answer': '◆',
        'options': ['◆', '◇', '●', '■']
      },
    ];
    
    final selected = patterns[DateTime.now().millisecondsSinceEpoch % patterns.length];
    
    return PuzzleMission(
      id: DateTime.now().millisecondsSinceEpoch,
      type: PuzzleType.patternMatch,
      question: '${selected['question']}\n\n🔷 ${selected['pattern']}\n\n${selected['hint']}',
      options: List<String>.from(selected['options'] as List),
      correctAnswer: selected['answer'] as String,
    );
  }

  static PuzzleMission _generateColorSequence() {
    // 색상 순서 퍼즐
    final colorSequences = [
      {
        'question': '다음 색상 순서에서 빈칸(?)에 들어갈 색을 찾으세요',
        'sequence': '🔴 🔵 🔴 🔵 🔴 ?',
        'hint': '💡 힌트: 빨강과 파랑이 번갈아 나타남',
        'answer': '파랑',
        'options': ['빨강', '파랑', '노랑', '초록']
      },
      {
        'question': '다음 색상 순서에서 빈칸(?)에 들어갈 색을 찾으세요',
        'sequence': '🟢 🟡 🔴 🟢 🟡 ?',
        'hint': '💡 힌트: 초록, 노랑, 빨강 순서로 반복',
        'answer': '빨강',
        'options': ['빨강', '파랑', '노랑', '초록']
      },
      {
        'question': '다음 색상 순서에서 빈칸(?)에 들어갈 색을 찾으세요',
        'sequence': '🟣 🟠 🟣 🟠 🟣 ?',
        'hint': '💡 힌트: 보라와 주황이 번갈아 나타남',
        'answer': '주황',
        'options': ['보라', '주황', '노랑', '초록']
      },
    ];
    
    final selected = colorSequences[DateTime.now().millisecondsSinceEpoch % colorSequences.length];
    
    return PuzzleMission(
      id: DateTime.now().millisecondsSinceEpoch,
      type: PuzzleType.colorSequence,
      question: '${selected['question']}\n\n🎨 ${selected['sequence']}\n\n${selected['hint']}',
      options: List<String>.from(selected['options'] as List),
      correctAnswer: selected['answer'] as String,
    );
  }
}
