import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'mission_screen.dart';
import '../core/models/alarm.dart';
import '../core/services/gpt_realtime_service.dart';
import '../core/services/points_api_service.dart';
import '../core/models/api_models.dart';

class AlarmRingScreen extends StatefulWidget {
  final String alarmType;
  final String alarmTime;
  final Alarm? alarm; // 알람 객체 추가
  final int? alarmId; // 알람 ID 추가

  const AlarmRingScreen({
    super.key,
    required this.alarmType,
    required this.alarmTime,
    this.alarm,
    this.alarmId,
  });

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  Timer? _silenceTimer;
  int _silenceCountdown = 15; // 무발화 15초 유지 시 실패 처리
  Timer? _maxDurationTimer; // 최대 통화 시간 제한 (2분)
  bool _isRecording = false;
  bool _isCallActive = false; // 전화 받기 전까지는 false
  bool _isCallAccepted = false; // 전화 받았는지 여부
  DateTime? _lastUserSpeechTime; // 마지막 사용자 발화 시간
  bool _userHasSpoken = false; // 사용자가 한 번이라도 말했는지 여부

  // GPT 서비스
  final GPTRealtimeService _gptService = GPTRealtimeService();

  // WebRTC 오디오
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // 스누즈 관련
  int _snoozeCount = 0;
  static const int _maxSnoozeCount = 3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeRenderer();
    // 타이머는 전화 받은 후에 시작 (initState에서는 시작 안 함)
  }

  Future<void> _initializeRenderer() async {
    await _remoteRenderer.initialize();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  void _startSilenceTimer() {
    print('⏰ 무발화 타이머 시작 (15초)');
    _lastUserSpeechTime = DateTime.now(); // 타이머 시작 시점 기록

    _silenceTimer?.cancel(); // 기존 타이머 취소
    _silenceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCallAccepted) {
        // 전화를 아직 안 받았으면 타이머 정지
        return;
      }

      final now = DateTime.now();
      final secondsSinceLastSpeech = now.difference(_lastUserSpeechTime ?? now).inSeconds;

      if (secondsSinceLastSpeech >= 15) {
        print('❌ 15초 동안 사용자 발화 없음 - 알람 실패(무발화)로 종료');
        _endCallNoTalk();
      } else {
        setState(() {
          _silenceCountdown = 15 - secondsSinceLastSpeech;
        });
      }
    });
  }

  void _resetSilenceTimer() {
    print('🔄 무발화 타이머 리셋 (사용자 발화 감지됨)');
    _lastUserSpeechTime = DateTime.now();
    setState(() {
      _silenceCountdown = 15;
    });

    // 사용자가 처음으로 말했으면 1차 성공! GPT가 마무리 멘트 후 알아서 종료함
    if (!_userHasSpoken) {
      _userHasSpoken = true;
      print('✅ 사용자 첫 발화 감지 - 알람 1차 성공! GPT 응답 대기 중...');
      // GPT가 응답하고 자연스럽게 종료할 때까지 기다림
      // response.done 메시지 후 자동으로 MissionScreen으로 이동
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();

    // 스피커폰 비활성화
    Helper.setSpeakerphoneOn(false).catchError((e) {
      print('❌ 스피커폰 비활성화 실패: $e');
    });

    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 알람 화면에서는 뒤로가기 비활성화
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: widget.alarmType == '전화알람' 
          ? _buildCallInterface()
          : _buildRegularAlarmInterface(),
      ),
    );
  }

  Widget _buildRegularAlarmInterface() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          
          // 알람 아이콘
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.alarm,
                size: 100,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 알람 정보
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Text(
                  '${widget.alarmType} 알람',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '시간: ${widget.alarmTime}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // 버튼들
          FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 스누즈 버튼은 일반알람에서만 표시
                if (widget.alarmType != '전화알람')
                  _buildActionButton(
                    icon: Icons.snooze,
                    label: '스누즈',
                    color: Colors.orange,
                    onPressed: _snoozeAlarm,
                  ),
                _buildActionButton(
                  icon: Icons.stop,
                  label: '종료',
                  color: Colors.red,
                  onPressed: _stopAlarm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallInterface() {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // 상단 프로필
              _buildCallHeader(),

              // 음성 상태 표시 (채팅 로그 대신)
              Expanded(
                child: _buildVoiceStatus(),
              ),

              // 하단 컨트롤
              _buildCallControls(),
            ],
          ),
          // RTCVideoView를 숨겨진 상태로 추가 (오디오 재생을 위해 필요)
          Positioned(
            left: 0,
            top: 0,
            width: 1,
            height: 1,
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Text(
              'AC',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'AningCall',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '알람 시간: ${widget.alarmTime}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (_isCallAccepted) ...[
            const SizedBox(height: 8),
            Text(
              '무발화 $_silenceCountdown초 후 종료',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '전화가 왔습니다',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 음성 파형 애니메이션
          _buildVoiceWaveform(),
          
          const SizedBox(height: 32),
          
          // 상태 메시지
          Text(
            _isCallAccepted 
              ? (_isCallActive ? '음성 대화 중...' : '통화 종료')
              : '전화를 받으세요',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 통화 중 대화 로그는 화면에 표시하지 않음 (요청사항)

          // 마이크 상태
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isRecording ? Icons.mic : Icons.mic_off,
                  color: _isRecording ? Colors.red : Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording ? '음성 인식 중' : '음성 인식 대기',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (대화 로그 프리뷰 비표시)

  Widget _buildVoiceWaveform() {
    return SizedBox(
      width: 200,
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            width: 8,
            height: _isCallActive ? (20 + (index * 10)) : 10,
            decoration: BoxDecoration(
              color: _isCallActive ? Colors.white : Colors.white30,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 전화 거절 버튼
          _buildControlButton(
            icon: Icons.call_end,
            label: '거절',
            color: Colors.red,
            onPressed: _rejectCall,
          ),
          
          // 전화 받기 버튼
          _buildControlButton(
            icon: Icons.call,
            label: '받기',
            color: Colors.green,
            onPressed: _acceptCall,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 40, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 30, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _acceptCall() async {
    setState(() {
      _isCallActive = true;
      _isCallAccepted = true;
      _isRecording = true;
    });

    // GPT 서비스 시작
    if (widget.alarmId != null) {
      try {
        // 알람 정보 로깅
        if (widget.alarm != null) {
          print('📞 전화 받기 - 알람 정보:');
          print('  - 제목: ${widget.alarm!.tag}');
          print('  - 시간: ${widget.alarm!.time}');
          print('  - 백엔드 ID: ${widget.alarm!.backendAlarmId}');
          print('  - 로컬 ID: ${widget.alarm!.id}');
        } else {
          print('📞 전화 받기 - alarmId만 전달됨: ${widget.alarmId}');
        }

        print('📞 GPT 서비스 시작');

        // GPT 서비스 콜백 설정 (통화 시작 전에 설정해야 함!)
        _gptService.onCallStarted = () {
          print('✅ GPT 통화 시작됨 - 무발화 타이머 시작');
          _startSilenceTimer(); // 통화 시작하면 타이머 시작
        };

        _gptService.onCallEnded = () {
          print('📞 GPT 통화 종료됨');
          Navigator.of(context).pop();
        };

        _gptService.onSnoozeRequested = (alarmId, snoozeMinutes) {
          print('😴 스누즈 요청됨: $snoozeMinutes분');
          // 스누즈 처리 (GPT 서비스에서 자동 처리됨)
        };

        // 사용자 발화 감지 콜백 (타이머 리셋용)
        _gptService.onUserSpeechDetected = () {
          if (mounted) {
            _resetSilenceTimer();
          }
        };

        // 대화 내용 표시용 콜백
        // 통화 화면에 대화 로그는 표시하지 않음

        // GPT 응답 완료 콜백 (사용자 발화 후)
        _gptService.onGPTResponseCompleted = () {
          if (mounted) {
            // 자동 종료/이동을 하지 않고 통화를 계속 유지합니다.
            // 무발화 60초 타이머로 종료를 제어합니다.
            print('🎯 GPT 응답 완료 - 통화 유지 (자동 종료 안 함)');
          }
        };

        // 원격 오디오 스트림 설정 (통화 시작 전에 설정!)
        _gptService.onRemoteStream = (stream) async {
          print('🔊 원격 스트림 설정');

          try {
            // 렌더러에 스트림 설정
            await _remoteRenderer.setSrcObject(stream: stream);
            print('✅ 렌더러에 스트림 설정 완료');

            // 스피커폰 활성화 (Android/iOS)
            await Helper.setSpeakerphoneOn(true);
            print('📢 스피커폰 활성화 완료');

            // 오디오 트랙 활성화 확인
            final audioTracks = stream.getAudioTracks();
            print('🎵 오디오 트랙 개수: ${audioTracks.length}');
            for (var track in audioTracks) {
              print('🎵 트랙 ${track.id}:');
              print('  - enabled: ${track.enabled}');
              print('  - kind: ${track.kind}');
              print('  - label: ${track.label}');

              track.enabled = true;
              track.enableSpeakerphone(true);

              print('  - 활성화 완료');
            }

            // 강제 리렌더링
            if (mounted) {
              setState(() {});
              print('✅ UI 리렌더링 완료');
            }
          } catch (e) {
            print('❌ 스트림 설정 오류: $e');
          }
        };

        // 콜백 설정 후 통화 시작
        await _gptService.startMorningCall(alarmId: widget.alarmId!);

        // 최대 통화 시간 제한(2분)
        _maxDurationTimer?.cancel();
        _maxDurationTimer = Timer(const Duration(minutes: 2), () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('최대 통화 시간(2분)이 초과되어 통화를 종료합니다.')),
          );
          _stopAlarm();
        });

      } catch (e) {
        print('❌ GPT 서비스 시작 실패: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('통화 연결 실패: $e')),
        );
      }
    }
  }

  void _rejectCall() {
    setState(() {
      _isCallActive = false;
    });
    
    // 알람 종료
    _stopAlarm();
  }


  void _snoozeAlarm() {
    if (_snoozeCount < _maxSnoozeCount) {
      setState(() {
        _snoozeCount++;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('스누즈 $_snoozeCount/$_maxSnoozeCount - 5분 후 다시 알람이 울립니다'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // 5분 후 알람 재설정 로직
      Timer(const Duration(minutes: 5), () {
        // 알람 재설정
      });
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최대 스누즈 횟수에 도달했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopAlarm() {
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    setState(() {
      _isCallActive = false;
    });
    // 통화 종료 처리
    try {
      _gptService.endMorningCall();
    } catch (_) {}
    
    // 미션 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MissionScreen(
          alarmTitle: '${widget.alarmType} 알람',
          onMissionCompleted: () async {
            // 미션 완료 시 포인트 획득
            const basePoints = 10;
            const bonusPoints = 0; // 점수에 따른 보너스 (필요 시 계산)

            try {
              final pointsService = PointsApiService();
              final missionId = DateTime.now().millisecondsSinceEpoch.toString();

              // 1. 기본 포인트 - GRADE (일일 제한 적용)
              await pointsService.earnPoints(EarnPointsRequest(
                type: 'GRADE',
                amount: basePoints,
                description: '미션 완료 (등급 포인트)',
                metadata: {'missionId': missionId, 'reason': 'mission_complete', 'pointType': 'base'},
              ));
              print('✅ 서버 GRADE 기본 포인트 획득: +$basePoints');

              // 2. 기본 포인트 - CONSUMPTION (일일 제한 적용)
              await pointsService.earnPoints(EarnPointsRequest(
                type: 'CONSUMPTION',
                amount: basePoints,
                description: '미션 완료 (소비 포인트)',
                metadata: {'missionId': missionId, 'reason': 'mission_complete', 'pointType': 'base'},
              ));
              print('✅ 서버 CONSUMPTION 기본 포인트 획득: +$basePoints');

              // 3. 보너스 포인트가 있으면 별도 전송 (일일 제한 제외)
              if (bonusPoints > 0) {
                await pointsService.earnPoints(EarnPointsRequest(
                  type: 'GRADE',
                  amount: bonusPoints,
                  description: '미션 완료 보너스 (등급 포인트)',
                  metadata: {'missionId': missionId, 'reason': 'mission_bonus', 'pointType': 'bonus'},
                ));
                print('✅ 서버 GRADE 보너스 포인트 획득: +$bonusPoints');

                await pointsService.earnPoints(EarnPointsRequest(
                  type: 'CONSUMPTION',
                  amount: bonusPoints,
                  description: '미션 완료 보너스 (소비 포인트)',
                  metadata: {'missionId': missionId, 'reason': 'mission_bonus', 'pointType': 'bonus'},
                ));
                print('✅ 서버 CONSUMPTION 보너스 포인트 획득: +$bonusPoints');
              }
            } catch (e) {
              print('⚠️ 포인트 획득 실패: $e');
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _endCallNoTalk() {
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    setState(() {
      _isCallActive = false;
    });
    // 실패 종료 처리
    try {
      _gptService.endMorningCallNoTalk();
    } catch (_) {}
    
    // 미션 화면으로 이동 (실패 상태)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MissionScreen(
          alarmTitle: '${widget.alarmType} 알람',
          onMissionCompleted: () async {
            // 미션 완료 시 포인트 획득
            const basePoints = 10;
            const bonusPoints = 0; // 점수에 따른 보너스 (필요 시 계산)

            try {
              final pointsService = PointsApiService();
              final missionId = DateTime.now().millisecondsSinceEpoch.toString();

              // 1. 기본 포인트 - GRADE (일일 제한 적용)
              await pointsService.earnPoints(EarnPointsRequest(
                type: 'GRADE',
                amount: basePoints,
                description: '미션 완료 (등급 포인트)',
                metadata: {'missionId': missionId, 'reason': 'mission_complete', 'pointType': 'base'},
              ));
              print('✅ 서버 GRADE 기본 포인트 획득: +$basePoints');

              // 2. 기본 포인트 - CONSUMPTION (일일 제한 적용)
              await pointsService.earnPoints(EarnPointsRequest(
                type: 'CONSUMPTION',
                amount: basePoints,
                description: '미션 완료 (소비 포인트)',
                metadata: {'missionId': missionId, 'reason': 'mission_complete', 'pointType': 'base'},
              ));
              print('✅ 서버 CONSUMPTION 기본 포인트 획득: +$basePoints');

              // 3. 보너스 포인트가 있으면 별도 전송 (일일 제한 제외)
              if (bonusPoints > 0) {
                await pointsService.earnPoints(EarnPointsRequest(
                  type: 'GRADE',
                  amount: bonusPoints,
                  description: '미션 완료 보너스 (등급 포인트)',
                  metadata: {'missionId': missionId, 'reason': 'mission_bonus', 'pointType': 'bonus'},
                ));
                print('✅ 서버 GRADE 보너스 포인트 획득: +$bonusPoints');

                await pointsService.earnPoints(EarnPointsRequest(
                  type: 'CONSUMPTION',
                  amount: bonusPoints,
                  description: '미션 완료 보너스 (소비 포인트)',
                  metadata: {'missionId': missionId, 'reason': 'mission_bonus', 'pointType': 'bonus'},
                ));
                print('✅ 서버 CONSUMPTION 보너스 포인트 획득: +$bonusPoints');
              }
            } catch (e) {
              print('⚠️ 포인트 획득 실패: $e');
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
