import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../environment/environment.dart';
import '../models/api_models.dart' as models;

/// API 예외 클래스
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode, Code: $errorCode)';
}

/// 네트워크 예외 클래스
class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// 인증 예외 클래스
class AuthenticationException extends ApiException {
  const AuthenticationException(super.message) : super(statusCode: 401);
}

/// 권한 예외 클래스
class AuthorizationException extends ApiException {
  const AuthorizationException(super.message) : super(statusCode: 403);
}

/// 서버 예외 클래스
class ServerException extends ApiException {
  const ServerException(super.message, {int? statusCode}) 
      : super(statusCode: statusCode ?? 500);
}

/// 기본 API 서비스 클래스
/// HTTP 요청 처리, 인증, 에러 처리 등 공통 기능 제공
class BaseApiService {
  static final BaseApiService _instance = BaseApiService._internal();
  factory BaseApiService() => _instance;
  BaseApiService._internal();

  late http.Client _httpClient;
  String? _accessToken;
  String? _refreshToken;
  SharedPreferences? _prefs;

  /// HTTP 클라이언트 초기화
  Future<void> initialize() async {
    _httpClient = http.Client();
    _prefs = await SharedPreferences.getInstance();
    
    // 저장된 토큰 로드
    await _loadStoredTokens();
  }
  
  /// 저장된 토큰 로드
  Future<void> _loadStoredTokens() async {
    if (_prefs != null) {
      _accessToken = _prefs!.getString('access_token');
      _refreshToken = _prefs!.getString('refresh_token');
    }
  }
  
  /// 토큰 저장
  Future<void> _saveTokens() async {
    if (_prefs != null) {
      if (_accessToken != null) {
        await _prefs!.setString('access_token', _accessToken!);
      }
      if (_refreshToken != null) {
        await _prefs!.setString('refresh_token', _refreshToken!);
      }
    }
  }
  
  /// 토큰 삭제
  Future<void> _clearStoredTokens() async {
    if (_prefs != null) {
      await _prefs!.remove('access_token');
      await _prefs!.remove('refresh_token');
    }
  }

  /// 액세스 토큰 설정
  Future<void> setAccessToken(String? token) async {
    _accessToken = token;
    await _saveTokens();
  }

  /// 리프레시 토큰 설정
  Future<void> setRefreshToken(String? token) async {
    _refreshToken = token;
    await _saveTokens();
  }

  /// 현재 액세스 토큰 반환
  String? get accessToken => _accessToken;

  /// 현재 리프레시 토큰 반환
  String? get refreshToken => _refreshToken;
  
  /// 저장된 인증 토큰 반환 (만료 시간 포함)
  models.AuthToken? getStoredAuthToken() {
    if (_accessToken == null || _refreshToken == null) return null;
    
    try {
      // JWT 토큰에서 만료 시간 추출
      final accessTokenDecoded = JwtDecoder.decode(_accessToken!);
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        (accessTokenDecoded['exp'] as int) * 1000,
      );
      
      return models.AuthToken(
        accessToken: _accessToken!,
        refreshToken: _refreshToken!,
        expiresAt: expiresAt,
      );
    } catch (e) {
      // JWT 디코딩 실패 시 null 반환
      debugPrint('JWT 토큰 디코딩 실패: $e');
      return null;
    }
  }

  /// 인증 토큰 설정
  Future<void> setAuthTokens(models.AuthToken authToken) async {
    _accessToken = authToken.accessToken;
    _refreshToken = authToken.refreshToken;
    await _saveTokens();
  }

  /// 인증 토큰 제거
  Future<void> clearAuthTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _clearStoredTokens();
  }

  /// 기본 헤더 생성
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// URL 생성
  String _buildUrl(String path) {
    final baseUrl = EnvironmentConfig.baseUrl.replaceAll(RegExp(r'/+$'), ''); // 끝의 슬래시 제거
    final cleanPath = path.startsWith('/') ? path : '/$path'; // 시작에 슬래시 보장
    return '$baseUrl$cleanPath';
  }

  /// GET 요청
  Future<models.ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl(path));
      final uriWithQuery = queryParameters != null 
          ? uri.replace(queryParameters: queryParameters)
          : uri;

      debugPrint('🌐 GET 요청 시작: $uriWithQuery');
      debugPrint('📋 요청 헤더: ${_getHeaders(additionalHeaders: headers)}');

      final response = await _httpClient.get(
        uriWithQuery,
        headers: _getHeaders(additionalHeaders: headers),
      );

      debugPrint('✅ GET 응답 성공: ${response.statusCode}');
      debugPrint('📄 응답 헤더: ${response.headers}');
      debugPrint('📝 응답 본문: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      debugPrint('❌ 소켓 연결 실패: $e');
      throw NetworkException('인터넷 연결을 확인해주세요: $e');
    } on HttpException catch (e) {
      debugPrint('❌ HTTP 오류: ${e.message}');
      throw NetworkException('네트워크 오류: ${e.message}');
    } on TimeoutException catch (e) {
      debugPrint('❌ 타임아웃 오류: $e');
      throw NetworkException('요청 시간 초과: $e');
    } catch (e) {
      debugPrint('🔥 예상치 못한 오류: $e (타입: ${e.runtimeType})');
      if (e is ApiException) rethrow;
      throw ApiException('GET 요청 실패: $e');
    }
  }

  /// POST 요청
  Future<models.ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl(path));
      // Debug: POST 요청 시작: $uri
      // Debug: 요청 헤더: ${_getHeaders(additionalHeaders: headers)}
      // Debug: 요청 본문: ${body != null ? jsonEncode(body) : 'null'}

      final response = await _httpClient.post(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      );

      // Debug: POST 응답 성공: ${response.statusCode}
      // Debug: 응답 헤더: ${response.headers}
      // Debug: 응답 본문: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      // Debug: 소켓 연결 실패: $e
      throw NetworkException('인터넷 연결을 확인해주세요: $e');
    } on HttpException catch (e) {
      // Debug: HTTP 오류: ${e.message}
      throw NetworkException('네트워크 오류: ${e.message}');
    } on TimeoutException catch (e) {
      // Debug: 타임아웃 오류: $e
      throw NetworkException('요청 시간 초과: $e');
    } catch (e) {
      // Debug: 예상치 못한 오류: $e (타입: ${e.runtimeType})
      if (e is ApiException) rethrow;
      throw ApiException('POST 요청 실패: $e');
    }
  }

  /// PUT 요청
  Future<models.ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl(path));
      // Debug: PUT 요청 시작: $uri
      // Debug: 요청 헤더: ${_getHeaders(additionalHeaders: headers)}
      // Debug: 요청 본문: ${body != null ? jsonEncode(body) : 'null'}

      final response = await _httpClient.put(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      );

      // Debug: PUT 응답 성공: ${response.statusCode}
      // Debug: 응답 헤더: ${response.headers}
      // Debug: 응답 본문: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      // Debug: 소켓 연결 실패: $e
      throw NetworkException('인터넷 연결을 확인해주세요: $e');
    } on HttpException catch (e) {
      // Debug: HTTP 오류: ${e.message}
      throw NetworkException('네트워크 오류: ${e.message}');
    } on TimeoutException catch (e) {
      // Debug: 타임아웃 오류: $e
      throw NetworkException('요청 시간 초과: $e');
    } catch (e) {
      // Debug: 예상치 못한 오류: $e (타입: ${e.runtimeType})
      if (e is ApiException) rethrow;
      throw ApiException('PUT 요청 실패: $e');
    }
  }

  /// PATCH 요청
  Future<models.ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl(path));
      // Debug: PATCH 요청 시작: $uri
      // Debug: 요청 헤더: ${_getHeaders(additionalHeaders: headers)}
      // Debug: 요청 본문: ${body != null ? jsonEncode(body) : 'null'}

      final response = await _httpClient.patch(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
        body: body != null ? jsonEncode(body) : null,
      );

      // Debug: PATCH 응답 성공: ${response.statusCode}
      // Debug: 응답 헤더: ${response.headers}
      // Debug: 응답 본문: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      // Debug: 소켓 연결 실패: $e
      throw NetworkException('인터넷 연결을 확인해주세요: $e');
    } on HttpException catch (e) {
      // Debug: HTTP 오류: ${e.message}
      throw NetworkException('네트워크 오류: ${e.message}');
    } on TimeoutException catch (e) {
      // Debug: 타임아웃 오류: $e
      throw NetworkException('요청 시간 초과: $e');
    } catch (e) {
      // Debug: 예상치 못한 오류: $e (타입: ${e.runtimeType})
      if (e is ApiException) rethrow;
      throw ApiException('PATCH 요청 실패: $e');
    }
  }

  /// DELETE 요청
  Future<models.ApiResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl(path));
      // Debug: DELETE 요청 시작: $uri
      // Debug: 요청 헤더: ${_getHeaders(additionalHeaders: headers)}

      final response = await _httpClient.delete(
        uri,
        headers: _getHeaders(additionalHeaders: headers),
      );

      // Debug: DELETE 응답 성공: ${response.statusCode}
      // Debug: 응답 헤더: ${response.headers}
      // Debug: 응답 본문: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      // Debug: 소켓 연결 실패: $e
      throw NetworkException('인터넷 연결을 확인해주세요: $e');
    } on HttpException catch (e) {
      // Debug: HTTP 오류: ${e.message}
      throw NetworkException('네트워크 오류: ${e.message}');
    } on TimeoutException catch (e) {
      // Debug: 타임아웃 오류: $e
      throw NetworkException('요청 시간 초과: $e');
    } catch (e) {
      // Debug: 예상치 못한 오류: $e (타입: ${e.runtimeType})
      if (e is ApiException) rethrow;
      throw ApiException('DELETE 요청 실패: $e');
    }
  }

  /// HTTP 응답 처리
  models.ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    // Debug: 응답 상태 코드: ${response.statusCode}
    // Debug: 응답 본문 길이: ${response.body.length}

    // 상태 코드에 따른 처리
    switch (response.statusCode) {
      case 200:
      case 201:
        // Debug: 성공 응답 처리 중...
        return _parseSuccessResponse<T>(response, fromJson);
      case 400:
        // Debug: 잘못된 요청 (400)
        throw _parseErrorResponse(response, '잘못된 요청입니다');
      case 401:
        // Debug: 인증 실패 (401)
        throw _parseAuthenticationError(response);
      case 403:
        // Debug: 권한 없음 (403)
        throw AuthorizationException(_parseErrorMessage(response, '권한이 없습니다'));
      case 404:
        // Debug: 리소스 없음 (404)
        throw ApiException(_parseErrorMessage(response, '요청한 리소스를 찾을 수 없습니다'), statusCode: 404);
      case 422:
        // Debug: 입력 데이터 오류 (422)
        throw ApiException(_parseErrorMessage(response, '입력 데이터가 올바르지 않습니다'), statusCode: 422);
      case 500:
        // Debug: 서버 내부 오류 (500)
        throw ServerException(_parseErrorMessage(response, '서버 내부 오류가 발생했습니다'));
      case 502:
        // Debug: 게이트웨이 오류 (502)
        throw ServerException(_parseErrorMessage(response, '서버 게이트웨이 오류가 발생했습니다'), statusCode: 502);
      case 503:
        // Debug: 서비스 사용 불가 (503)
        throw ServerException(_parseErrorMessage(response, '서버를 일시적으로 사용할 수 없습니다'), statusCode: 503);
      default:
        // Debug: 알 수 없는 오류 (${response.statusCode})
        throw ServerException(
          _parseErrorMessage(response, '알 수 없는 서버 오류가 발생했습니다'),
          statusCode: response.statusCode,
        );
    }
  }

  /// 성공 응답 파싱
  models.ApiResponse<T> _parseSuccessResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      if (response.body.isEmpty) {
        return models.ApiResponse<T>(success: true, data: null, message: null, statusCode: response.statusCode);
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('🔍 파싱 디버깅 - jsonData: $jsonData');
      
      // 서버 응답 구조: {"success": true, "data": {...}}
      final success = jsonData['success'] as bool? ?? false;
      final data = jsonData['data'];
      final message = jsonData['message'] as String?;
      
      debugPrint('🔍 파싱 디버깅 - success: $success');
      debugPrint('🔍 파싱 디버깅 - data: $data');
      debugPrint('🔍 파싱 디버깅 - data type: ${data.runtimeType}');
      debugPrint('🔍 파싱 디버깅 - fromJson != null: ${fromJson != null}');
      
      if (!success) {
        throw ApiException(message ?? '서버에서 오류가 발생했습니다');
      }
      
      if (fromJson != null && data != null) {
        debugPrint('🔍 파싱 디버깅 - fromJson 호출 시작');
        try {
          if (data is Map<String, dynamic>) {
            final parsedData = fromJson(data);
            debugPrint('🔍 파싱 디버깅 - fromJson 성공(Map): $parsedData');
            return models.ApiResponse.success(parsedData, message: message);
          } else if (data is List) {
            // 호환성: 서버가 data를 리스트로 반환하는 경우 fromJson이 Map을 기대하면 래핑해서 전달
            final wrapped = <String, dynamic>{'data': data};
            final parsedData = fromJson(wrapped);
            debugPrint('🔍 파싱 디버깅 - fromJson 성공(List wrapped): $parsedData');
            return models.ApiResponse.success(parsedData, message: message);
          } else {
            debugPrint('🔍 파싱 디버깅 - fromJson에 전달 불가한 타입: ${data.runtimeType}');
            throw ApiException('지원하지 않는 응답 데이터 형식: ${data.runtimeType}');
          }
        } catch (e) {
          debugPrint('🔍 파싱 디버깅 - fromJson 실패: $e');
          rethrow;
        }
      } else if (data != null) {
        // fromJson이 없고 원시 data를 그대로 전달해야 하는 경우
        final T? typedData = data is T ? data : null;
        return models.ApiResponse<T>(success: true, data: typedData, message: message, statusCode: response.statusCode);
      } else {
        return models.ApiResponse<T>(success: true, data: null, message: message, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('🔍 파싱 디버깅 - 전체 오류: $e');
      throw ApiException('응답 파싱 오류: $e');
    }
  }

  /// 에러 응답 파싱
  ApiException _parseErrorResponse(http.Response response, String defaultMessage) {
    final errorMessage = _parseErrorMessage(response, defaultMessage);
    return ApiException(errorMessage, statusCode: response.statusCode);
  }

  /// 인증 에러 파싱
  AuthenticationException _parseAuthenticationError(http.Response response) {
    final errorMessage = _parseErrorMessage(response, '인증이 필요합니다');
    return AuthenticationException(errorMessage);
  }

  /// 에러 메시지 추출
  String _parseErrorMessage(http.Response response, String defaultMessage) {
    try {
      if (response.body.isEmpty) return defaultMessage;
      
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonData['message'] as String? ?? 
             jsonData['error'] as String? ?? 
             defaultMessage;
    } catch (e) {
      return defaultMessage;
    }
  }

  /// 토큰 갱신
  Future<models.ApiResponse<models.AuthToken>> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw const AuthenticationException('리프레시 토큰이 없습니다');
    }

    try {
      final response = await post<models.AuthToken>(
        '/api/auth/refresh',
        body: {'refreshToken': _refreshToken},
        fromJson: (json) => models.AuthToken.fromJson(json),
      );

      if (response.success && response.data != null) {
        await setAuthTokens(response.data!);
      }
      return response;
    } catch (e) {
      debugPrint('토큰 갱신 실패: $e');
      await clearAuthTokens();
      rethrow;
    }
  }

  /// 리소스 정리
  void dispose() {
    _httpClient.close();
  }
}
