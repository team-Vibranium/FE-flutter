import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

/// OpenAI API 연결 테스트 서비스
class OpenAITestService {
  static final OpenAITestService _instance = OpenAITestService._internal();
  factory OpenAITestService() => _instance;
  OpenAITestService._internal();

  /// OpenAI API 연결 테스트
  Future<Map<String, dynamic>> testConnection() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'response': null,
      'error': null,
    };

    try {
      debugPrint('🧪 OpenAI API 연결 테스트 시작...');
      
      // final apiKey = ApiConstants.openaiApiKey; // 현재 비활성화
      const apiKey = '';
      
      if (apiKey.isEmpty || apiKey == 'your-openai-api-key-here') {
        result['message'] = 'API 키가 설정되지 않았습니다';
        return result;
      }

      debugPrint('🔑 API 키 확인됨: ${apiKey.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant. Respond in Korean.'
            },
            {
              'role': 'user',
              'content': '안녕하세요! API 연결 테스트입니다.'
            }
          ],
          'max_tokens': 50,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 API 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'] as String;
        
        result['success'] = true;
        result['message'] = 'OpenAI API 연결 성공!';
        result['response'] = aiResponse.trim();
        
        debugPrint('✅ OpenAI API 연결 성공!');
        debugPrint('🤖 AI 응답: ${aiResponse.trim()}');
        
      } else {
        final errorBody = response.body;
        result['message'] = 'API 오류: ${response.statusCode}';
        result['error'] = errorBody;
        
        debugPrint('❌ API 오류: ${response.statusCode}');
        debugPrint('📄 에러 내용: $errorBody');
      }

    } catch (e) {
      result['message'] = '연결 실패: $e';
      result['error'] = e.toString();
      
      debugPrint('💥 OpenAI API 연결 실패: $e');
    }

    return result;
  }

  /// 실시간 채팅 테스트
  Future<String> testChat(String message) async {
    try {
      debugPrint('💬 채팅 메시지 전송: $message');
      
      // final apiKey = ApiConstants.openaiApiKey; // 현재 비활성화
      const apiKey = '';
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''당신은 AningCall 알람 앱의 AI 어시스턴트입니다. 
사용자가 알람을 끄기 위해 대화하고 있습니다.
친근하고 도움이 되는 톤으로 대화하세요.'''
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'max_tokens': 150,
          'temperature': 0.8,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'] as String;
        
        debugPrint('🤖 AI 응답: ${aiResponse.trim()}');
        return aiResponse.trim();
        
      } else {
        debugPrint('❌ 채팅 API 오류: ${response.statusCode} - ${response.body}');
        return '죄송합니다. AI 서비스에 일시적인 문제가 있습니다.';
      }

    } catch (e) {
      debugPrint('💥 채팅 실패: $e');
      return '네트워크 연결을 확인해주세요.';
    }
  }
}
