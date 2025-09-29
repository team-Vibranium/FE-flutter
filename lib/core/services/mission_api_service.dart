import '../models/api_models.dart';
import 'base_api_service.dart';

/// 미션 결과 관련 API 서비스
/// 알람 미션 결과 저장 및 조회 API 호출 담당
class MissionApiService {
  static final MissionApiService _instance = MissionApiService._internal();
  factory MissionApiService() => _instance;
  MissionApiService._internal();

  final BaseApiService _baseApi = BaseApiService();

  /// 미션 결과 조회
  /// GET /api/mission-results
  Future<ApiResponse<List<MissionResult>>> getMissionResults({
    int? limit,
    int? offset,
    MissionType? missionType,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (missionType != null) queryParams['missionType'] = missionType.name;
      if (isCompleted != null) queryParams['isCompleted'] = isCompleted.toString();
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];

      return await _baseApi.get<List<MissionResult>>(
        '/api/mission-results',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final List<dynamic> resultsList = json['results'] ?? json['data'] ?? [];
          return resultsList
              .map((item) => MissionResult.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 특정 미션 결과 조회
  /// GET /api/mission-results/{id}
  Future<ApiResponse<MissionResult>> getMissionResult(String missionResultId) async {
    try {
      return await _baseApi.get<MissionResult>(
        '/api/mission-results/$missionResultId',
        fromJson: (json) => MissionResult.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 미션 결과 저장
  /// POST /api/mission-results
  Future<ApiResponse<MissionResult>> saveMissionResult({
    required String alarmId,
    required MissionType missionType,
    required bool isCompleted,
    required int score,
    Map<String, dynamic>? resultData,
  }) async {
    try {
      final body = {
        'alarmId': alarmId,
        'missionType': missionType.name,
        'isCompleted': isCompleted,
        'score': score,
        'completedAt': DateTime.now().toIso8601String(),
      };

      if (resultData != null) {
        body['resultData'] = resultData;
      }

      return await _baseApi.post<MissionResult>(
        '/api/mission-results',
        body: body,
        fromJson: (json) => MissionResult.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 미션 결과 업데이트
  /// PUT /api/mission-results/{id}
  Future<ApiResponse<MissionResult>> updateMissionResult(
    String missionResultId, {
    bool? isCompleted,
    int? score,
    Map<String, dynamic>? resultData,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (isCompleted != null) body['isCompleted'] = isCompleted;
      if (score != null) body['score'] = score;
      if (resultData != null) body['resultData'] = resultData;

      return await _baseApi.put<MissionResult>(
        '/api/mission-results/$missionResultId',
        body: body,
        fromJson: (json) => MissionResult.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 미션 결과 삭제
  /// DELETE /api/mission-results/{id}
  Future<ApiResponse<void>> deleteMissionResult(String missionResultId) async {
    try {
      return await _baseApi.delete<void>('/api/mission-results/$missionResultId');
    } catch (e) {
      rethrow;
    }
  }

  /// 수학 미션 결과 저장
  Future<ApiResponse<MissionResult>> saveMathMissionResult({
    required String alarmId,
    required bool isCompleted,
    required int score,
    required List<Map<String, dynamic>> problems,
    required int correctAnswers,
    required int totalProblems,
    required int timeSpent, // 초 단위
  }) async {
    return saveMissionResult(
      alarmId: alarmId,
      missionType: MissionType.MATH,
      isCompleted: isCompleted,
      score: score,
      resultData: {
        'problems': problems,
        'correctAnswers': correctAnswers,
        'totalProblems': totalProblems,
        'timeSpent': timeSpent,
        'accuracy': (correctAnswers / totalProblems * 100).toInt(),
      },
    );
  }

  /// 기억 게임 미션 결과 저장
  Future<ApiResponse<MissionResult>> saveMemoryMissionResult({
    required String alarmId,
    required bool isCompleted,
    required int score,
    required List<int> sequence,
    required List<int> userInput,
    required int level,
    required int timeSpent,
  }) async {
    return saveMissionResult(
      alarmId: alarmId,
      missionType: MissionType.MEMORY,
      isCompleted: isCompleted,
      score: score,
      resultData: {
        'sequence': sequence,
        'userInput': userInput,
        'level': level,
        'timeSpent': timeSpent,
        'accuracy': _calculateSequenceAccuracy(sequence, userInput),
      },
    );
  }

  /// 퍼즐 미션 결과 저장
  Future<ApiResponse<MissionResult>> savePuzzleMissionResult({
    required String alarmId,
    required bool isCompleted,
    required int score,
    required String puzzleType,
    required int moves,
    required int timeSpent,
    Map<String, dynamic>? puzzleData,
  }) async {
    return saveMissionResult(
      alarmId: alarmId,
      missionType: MissionType.PUZZLE,
      isCompleted: isCompleted,
      score: score,
      resultData: {
        'puzzleType': puzzleType,
        'moves': moves,
        'timeSpent': timeSpent,
        'puzzleData': puzzleData,
      },
    );
  }

  /// 음성 인식 미션 결과 저장
  Future<ApiResponse<MissionResult>> saveVoiceMissionResult({
    required String alarmId,
    required bool isCompleted,
    required int score,
    required String targetPhrase,
    required String recognizedText,
    required double confidence,
    required int attempts,
  }) async {
    return saveMissionResult(
      alarmId: alarmId,
      missionType: MissionType.QUIZ,
      isCompleted: isCompleted,
      score: score,
      resultData: {
        'targetPhrase': targetPhrase,
        'recognizedText': recognizedText,
        'confidence': confidence,
        'attempts': attempts,
        'similarity': _calculateTextSimilarity(targetPhrase, recognizedText),
      },
    );
  }

  /// 걷기 미션 결과 저장
  Future<ApiResponse<MissionResult>> saveWalkingMissionResult({
    required String alarmId,
    required bool isCompleted,
    required int score,
    required int targetSteps,
    required int actualSteps,
    required int timeSpent,
    List<Map<String, dynamic>>? locationData,
  }) async {
    return saveMissionResult(
      alarmId: alarmId,
      missionType: MissionType.QUIZ,
      isCompleted: isCompleted,
      score: score,
      resultData: {
        'targetSteps': targetSteps,
        'actualSteps': actualSteps,
        'timeSpent': timeSpent,
        'locationData': locationData,
        'completion': (actualSteps / targetSteps * 100).toInt(),
      },
    );
  }

  /// 최근 미션 결과 조회
  Future<ApiResponse<List<MissionResult>>> getRecentMissionResults({int limit = 10}) async {
    return getMissionResults(limit: limit, offset: 0);
  }

  /// 완료된 미션 결과만 조회
  Future<ApiResponse<List<MissionResult>>> getCompletedMissionResults({
    int? limit,
    int? offset,
  }) async {
    return getMissionResults(
      isCompleted: true,
      limit: limit,
      offset: offset,
    );
  }

  /// 특정 타입의 미션 결과 조회
  Future<ApiResponse<List<MissionResult>>> getMissionResultsByType(
    MissionType missionType, {
    int? limit,
    int? offset,
    bool? isCompleted,
  }) async {
    return getMissionResults(
      missionType: missionType,
      isCompleted: isCompleted,
      limit: limit,
      offset: offset,
    );
  }

  /// 특정 기간의 미션 결과 조회
  Future<ApiResponse<List<MissionResult>>> getMissionResultsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
    MissionType? missionType,
    bool? isCompleted,
  }) async {
    return getMissionResults(
      startDate: startDate,
      endDate: endDate,
      missionType: missionType,
      isCompleted: isCompleted,
      limit: limit,
      offset: offset,
    );
  }

  /// 시퀀스 정확도 계산 헬퍼 메서드
  int _calculateSequenceAccuracy(List<int> target, List<int> input) {
    if (target.isEmpty || input.isEmpty) return 0;
    
    int correct = 0;
    int minLength = target.length < input.length ? target.length : input.length;
    
    for (int i = 0; i < minLength; i++) {
      if (target[i] == input[i]) correct++;
    }
    
    return (correct / target.length * 100).toInt();
  }

  /// 텍스트 유사도 계산 헬퍼 메서드 (간단한 구현)
  double _calculateTextSimilarity(String target, String input) {
    if (target.isEmpty || input.isEmpty) return 0.0;
    
    target = target.toLowerCase().trim();
    input = input.toLowerCase().trim();
    
    if (target == input) return 100.0;
    
    // 간단한 레벤슈타인 거리 기반 유사도
    int distance = _levenshteinDistance(target, input);
    int maxLength = target.length > input.length ? target.length : input.length;
    
    return ((maxLength - distance) / maxLength * 100);
  }

  /// 레벤슈타인 거리 계산
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }
}
