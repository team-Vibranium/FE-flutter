import 'package:flutter/material.dart';
import 'dart:async';
import 'mission_screen.dart';
import '../core/models/alarm.dart';
import '../core/services/gpt_realtime_service.dart';

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
  int _silenceCountdown = 10;
  bool _isRecording = false;
  bool _isCallActive = false; // 전화 받기 전까지는 false
  bool _isCallAccepted = false; // 전화 받았는지 여부

  // GPT 서비스
  final GPTRealtimeService _gptService = GPTRealtimeService();

  // 스누즈 관련
  int _snoozeCount = 0;
  static const int _maxSnoozeCount = 3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.alarmType == '전화알람') {
      _startSilenceTimer();
    }
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
    _silenceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_silenceCountdown > 0) {
        setState(() {
          _silenceCountdown--;
        });
      } else {
        _stopAlarm();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _silenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.alarmType == '전화알람' 
        ? _buildCallInterface()
        : _buildRegularAlarmInterface(),
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
      child: Column(
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
              '무발화 ${_silenceCountdown}초 후 종료',
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

  Widget _buildVoiceWaveform() {
    return Container(
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
        print('📞 전화 받기 - GPT 서비스 시작');
        await _gptService.startMorningCall(alarmId: widget.alarmId!);
        
        // GPT 서비스 콜백 설정
        _gptService.onCallStarted = () {
          print('✅ GPT 통화 시작됨');
        };
        
        _gptService.onCallEnded = () {
          print('📞 GPT 통화 종료됨');
          Navigator.of(context).pop();
        };
        
        _gptService.onSnoozeRequested = (alarmId, snoozeMinutes) {
          print('😴 스누즈 요청됨: ${snoozeMinutes}분');
          // 스누즈 처리 (GPT 서비스에서 자동 처리됨)
        };
        
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
          content: Text('스누즈 ${_snoozeCount}/${_maxSnoozeCount} - 5분 후 다시 알람이 울립니다'),
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
    setState(() {
      _isCallActive = false;
    });
    
    // 미션 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MissionScreen(
          alarmTitle: '${widget.alarmType} 알람',
          onMissionCompleted: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}