import 'package:flutter/material.dart';
import 'dart:async';
import 'ai_call_screen.dart';
import 'mission_screen.dart';
import '../core/models/alarm.dart';

class AlarmRingScreen extends StatefulWidget {
  final String alarmType;
  final String alarmTime;
  final Alarm? alarm; // 알람 객체 추가

  const AlarmRingScreen({
    super.key,
    required this.alarmType,
    required this.alarmTime,
    this.alarm,
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
  bool _isCallActive = true;
  
  // 더미 대화 로그
  final List<Map<String, dynamic>> _conversationLog = [
    {'speaker': 'ai', 'message': '안녕하세요! 일어나실 시간이에요.', 'timestamp': '07:00:01'},
    {'speaker': 'ai', 'message': '오늘도 좋은 하루 되세요!', 'timestamp': '07:00:03'},
  ];

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
      setState(() {
        _silenceCountdown--;
      });
      
      if (_silenceCountdown <= 0) {
        _handleSilenceTimeout();
        timer.cancel();
      }
    });
  }

  void _handleSilenceTimeout() {
    setState(() {
      _isCallActive = false;
    });
    
    // 실패 처리 후 종료
    _showFailureDialog();
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
      backgroundColor: widget.alarmType == '전화알람' ? Colors.black : Colors.white,
      body: widget.alarmType == '전화알람' 
          ? _buildCallInterface()
          : _buildNormalAlarmInterface(),
    );
  }

  Widget _buildNormalAlarmInterface() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 큰 시계 UI
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.alarmTime,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          
          // 알람 제목
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              '일어날 시간이에요!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // 미션 해결 버튼 (메인 버튼)
          Container(
            width: 280,
            margin: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton.icon(
              onPressed: _startMission,
              icon: const Icon(Icons.psychology, size: 24),
              label: const Text(
                '🧩 미션 해결하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // AI 통화 버튼 (서브 버튼)
          Container(
            width: 280,
            margin: const EdgeInsets.only(bottom: 30),
            child: ElevatedButton.icon(
              onPressed: _startAICall,
              icon: const Icon(Icons.smart_toy, size: 20),
              label: const Text(
                'AI와 음성 통화하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // 버튼들
          FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
          
          // 대화 로그
          Expanded(
            child: _buildConversationLog(),
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
          if (_isCallActive) ...[
            const SizedBox(height: 8),
            Text(
              '무발화 ${_silenceCountdown}초 후 종료',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationLog() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: _conversationLog.length,
        itemBuilder: (context, index) {
          final message = _conversationLog[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isAI = message['speaker'] == 'ai';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Text(
                'AI',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isAI ? Colors.grey[800] : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['timestamp'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[600],
              child: const Text(
                '나',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // AI 통화 시작 버튼 (새로 추가)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton.icon(
              onPressed: _startAICall,
              icon: const Icon(Icons.smart_toy, size: 24),
              label: const Text(
                'AI와 음성 통화하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // 기존 컨트롤들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 마이크 버튼
              GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecording(),
                onTapCancel: () => _stopRecording(),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : Colors.green).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
          ),
          
          // 종료 버튼
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
            ],
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
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    // 녹음 시작 로직
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    // 녹음 중지 로직
  }

  void _snoozeAlarm() {
    // 스누즈 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('5분 후 다시 알람이 울립니다'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _stopAlarm() {
    // 알람 종료 로직
    _showSuccessDialog();
  }

  void _endCall() {
    // 통화 종료 로직
    _showFailureDialog();
  }

  /// 미션 해결 시작
  void _startMission() {
    final alarmTitle = widget.alarm?.tag ?? '알람';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MissionScreen(
          alarmTitle: alarmTitle,
          onMissionCompleted: () {
            // 미션 성공 시 알람 해제
            Navigator.pop(context); // 미션 스크린 닫기
            _showSuccessDialog();
          },
          onMissionFailed: () {
            // 미션 포기 시 원래 알람 화면으로 돌아옴
            Navigator.pop(context); // 미션 스크린 닫기
          },
        ),
      ),
    );
  }

  /// AI 통화 시작
  void _startAICall() {
    final alarmTitle = widget.alarm?.tag ?? '알람';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AICallScreen(
          alarmTitle: alarmTitle,
          onCallEnded: () {
            // AI 통화 종료 후 원래 알람 화면으로 돌아옴
            debugPrint('AI call ended');
          },
          onAlarmDismissed: () {
            // AI가 알람 해제를 승인한 경우
            _showSuccessDialog();
          },
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('알람 성공!'),
          ],
        ),
        content: const Text('오늘도 좋은 하루 되세요!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('알람 실패'),
          ],
        ),
        content: const Text('다음에는 꼭 일어나세요!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
