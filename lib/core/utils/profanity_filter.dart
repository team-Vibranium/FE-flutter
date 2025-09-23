/// 욕설 필터링 시스템
class ProfanityFilter {
  // 욕설 패턴 목록 (정규식)
  static final List<RegExp> _profanityPatterns = [
    // 기본적인 욕설 패턴들
    RegExp(r'시발|씨발|시팔|씨팔|ㅅㅂ|ㅆㅂ', caseSensitive: false),
    RegExp(r'병신|븅신|ㅂㅅ|바보|멍청이', caseSensitive: false),
    RegExp(r'개새끼|개놈|개년|ㄱㅅㅋ', caseSensitive: false),
    RegExp(r'좆|좇|ㅈ같|존나|졸라|쫄라', caseSensitive: false),
    RegExp(r'뻐큐|fuck|shit|damn|bitch', caseSensitive: false),
    RegExp(r'엿먹어|꺼져|닥쳐|죽어', caseSensitive: false),
    RegExp(r'미친|또라이|정신병|정신나간', caseSensitive: false),
    RegExp(r'애미|애비|에미|에비', caseSensitive: false),
    
    // 변형된 욕설 패턴들 (특수문자, 공백 등으로 우회)
    RegExp(r'ㅅ\s*ㅂ|ㅆ\s*ㅂ|ㅅ\.ㅂ|ㅆ\.ㅂ', caseSensitive: false),
    RegExp(r'ㅂ\s*ㅅ|ㅂ\.ㅅ', caseSensitive: false),
    RegExp(r's\s*h\s*i\s*t|f\s*u\s*c\s*k', caseSensitive: false),
    RegExp(r'시\s*발|씨\s*발|시\.발|씨\.발', caseSensitive: false),
    
    // 초성으로 된 욕설
    RegExp(r'ㅅㅂㄹㅁ|ㅂㅅ|ㄱㅅㅋ|ㅈㄴ', caseSensitive: false),
    
    // 숫자나 특수문자로 대체된 욕설
    RegExp(r'5ㅂ|씨8|ㅅ8|병5ㅣㄴ', caseSensitive: false),
  ];

  // 대체 문자 패턴
  static final Map<String, String> _replacementPatterns = {
    'ㅏ': 'a', 'ㅓ': 'o', 'ㅗ': 'o', 'ㅜ': 'u', 'ㅡ': 'u', 'ㅣ': 'i',
    'ㅑ': 'ya', 'ㅕ': 'yo', 'ㅛ': 'yo', 'ㅠ': 'yu',
    'ㅐ': 'ae', 'ㅔ': 'e', 'ㅒ': 'yae', 'ㅖ': 'ye',
    'ㅘ': 'wa', 'ㅙ': 'wae', 'ㅚ': 'oe', 'ㅝ': 'wo', 'ㅞ': 'we', 'ㅟ': 'wi', 'ㅢ': 'ui',
  };

  /// 텍스트에서 욕설을 검사합니다
  static bool containsProfanity(String text) {
    if (text.isEmpty) return false;
    
    // 텍스트 정규화 (공백, 특수문자 제거, 소문자 변환)
    final normalizedText = _normalizeText(text);
    
    // 각 욕설 패턴과 매칭 검사
    for (final pattern in _profanityPatterns) {
      if (pattern.hasMatch(normalizedText)) {
        return true;
      }
    }
    
    return false;
  }

  /// 욕설을 필터링하여 대체 문자로 변경합니다
  static String filterProfanity(String text, {String replacement = '*'}) {
    if (text.isEmpty) return text;
    
    String filteredText = text;
    
    // 각 욕설 패턴을 찾아서 대체
    for (final pattern in _profanityPatterns) {
      filteredText = filteredText.replaceAllMapped(pattern, (match) {
        final matchedText = match.group(0) ?? '';
        return replacement * matchedText.length;
      });
    }
    
    return filteredText;
  }

  /// 욕설을 검사하고 필터링 결과를 반환합니다
  static ProfanityCheckResult checkAndFilter(String text) {
    final hasProfanity = containsProfanity(text);
    final filteredText = hasProfanity ? filterProfanity(text) : text;
    final detectedWords = _getDetectedWords(text);
    
    return ProfanityCheckResult(
      originalText: text,
      filteredText: filteredText,
      hasProfanity: hasProfanity,
      detectedWords: detectedWords,
    );
  }

  /// 검출된 욕설 단어들을 반환합니다
  static List<String> _getDetectedWords(String text) {
    final List<String> detectedWords = [];
    final normalizedText = _normalizeText(text);
    
    for (final pattern in _profanityPatterns) {
      final matches = pattern.allMatches(normalizedText);
      for (final match in matches) {
        final word = match.group(0);
        if (word != null && !detectedWords.contains(word)) {
          detectedWords.add(word);
        }
      }
    }
    
    return detectedWords;
  }

  /// 텍스트를 정규화합니다 (공백, 특수문자 제거 등)
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w가-힣ㄱ-ㅎㅏ-ㅣ]'), '') // 특수문자, 공백 제거
        .replaceAll(RegExp(r'\s+'), '') // 연속된 공백 제거
        .trim();
  }

  /// 욕설 패턴을 동적으로 추가합니다
  static void addCustomPattern(String pattern) {
    try {
      final regExp = RegExp(pattern, caseSensitive: false);
      _profanityPatterns.add(regExp);
    } catch (e) {
      // 잘못된 정규식 패턴인 경우 무시
      print('Invalid regex pattern: $pattern');
    }
  }

  /// 욕설 패턴 목록을 초기화합니다
  static void clearCustomPatterns() {
    // 기본 패턴들만 남기고 커스텀 패턴 제거
    // 실제 구현에서는 기본 패턴과 커스텀 패턴을 구분하여 관리
  }

  /// 텍스트의 욕설 심각도를 평가합니다 (0-10 점수)
  static int evaluateSeverity(String text) {
    final result = checkAndFilter(text);
    if (!result.hasProfanity) return 0;
    
    int severity = 0;
    
    // 욕설 개수에 따른 점수
    severity += result.detectedWords.length * 2;
    
    // 강한 욕설 패턴에 대한 추가 점수
    final strongProfanityPatterns = [
      RegExp(r'시발|씨발|좆|좇', caseSensitive: false),
      RegExp(r'fuck|shit|bitch', caseSensitive: false),
    ];
    
    for (final pattern in strongProfanityPatterns) {
      if (pattern.hasMatch(text)) {
        severity += 3;
      }
    }
    
    return severity.clamp(0, 10);
  }
}

/// 욕설 필터링 결과 클래스
class ProfanityCheckResult {
  final String originalText;
  final String filteredText;
  final bool hasProfanity;
  final List<String> detectedWords;

  const ProfanityCheckResult({
    required this.originalText,
    required this.filteredText,
    required this.hasProfanity,
    required this.detectedWords,
  });

  @override
  String toString() {
    return 'ProfanityCheckResult(hasProfanity: $hasProfanity, '
           'detectedWords: $detectedWords, '
           'filteredText: $filteredText)';
  }
}

/// 욕설 필터링 설정
class ProfanityFilterSettings {
  static bool enableFilter = true;
  static String replacementChar = '*';
  static bool strictMode = false; // 엄격 모드 (더 많은 패턴 검사)
  static bool logDetections = false; // 검출 로깅 여부

  /// 설정을 초기화합니다
  static void reset() {
    enableFilter = true;
    replacementChar = '*';
    strictMode = false;
    logDetections = false;
  }
}
