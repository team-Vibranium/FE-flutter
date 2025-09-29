import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/morning_call_alarm_service.dart';
// 기본 Material Design 사용

/// 모닝콜 대화 화면
class MorningCallScreen extends ConsumerStatefulWidget {
  final String alarmTitle;
  final String? userName;

  const MorningCallScreen({
    super.key,
    required this.alarmTitle,
    this.userName,
  });

  @override
  ConsumerState<MorningCallScreen> createState() => _MorningCallScreenState();
}

class _MorningCallScreenState extends ConsumerState<MorningCallScreen>
    with TickerProviderStateMixin {
  final MorningCallAlarmService _alarmService = MorningCallAlarmService();
  
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isCallActive = false;
  bool _isConnecting = false;
  String _currentMessage = '';
  String _connectionStatus = '연결 중...';
  
  final List<String> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startMorningCall();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _startMorningCall() async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'GPT와 연결 중...';
    });

    try {
      await _alarmService.startMorningCall(
        alarmTitle: widget.alarmTitle,
        customUserName: widget.userName,
      );
      
      setState(() {
        _isCallActive = true;
        _isConnecting = false;
        _connectionStatus = '연결됨';
        _currentMessage = 'GPT와 연결되었습니다. 모닝콜이 시작됩니다!';
      });
      
      _waveController.repeat();
      _pulseController.repeat();
      
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = '연결 실패';
        _currentMessage = '모닝콜 시작에 실패했습니다: $e';
      });
    }
  }

  Future<void> _endMorningCall() async {
    await _alarmService.endMorningCall();
    
    setState(() {
      _isCallActive = false;
    });
    
    _waveController.stop();
    _pulseController.stop();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endMorningCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.indigo[900],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildConnectionStatus(),
                const SizedBox(height: 60),
                _buildVoiceVisualizer(),
                const SizedBox(height: 60),
                _buildCurrentMessage(),
                const Spacer(),
                _buildConversationHistory(),
                const SizedBox(height: 20),
                _buildControlButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          '🌅 모닝콜',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.alarmTitle,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.userName != null) ...[
          const SizedBox(height: 4),
          Text(
            '${widget.userName}님의 모닝콜',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectionStatus() {
    Color statusColor;
    IconData statusIcon;
    
    if (_isConnecting) {
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
    } else if (_isCallActive) {
      statusColor = Colors.green;
      statusIcon = Icons.phone;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.phone_disabled;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          _connectionStatus,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceVisualizer() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isCallActive ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.indigo.withValues(alpha: 0.8),
                    Colors.indigo.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.5),
                            blurRadius: 20 * _waveAnimation.value,
                            spreadRadius: 10 * _waveAnimation.value,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        size: 60,
                        color: Colors.indigo,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Colors.indigo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'GPT 모닝콜 도우미',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentMessage.isEmpty ? '대화를 시작해보세요!' : _currentMessage,
              style: TextStyle(
                color: Colors.white,
                height: 1.5,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationHistory() {
    if (_conversationHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '대화 기록',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _conversationHistory.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child:                     Text(
                      _conversationHistory[index],
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isCallActive ? _endMorningCall : null,
            icon: const Icon(Icons.call_end),
            label: const Text('통화 종료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isCallActive ? null : _startMorningCall,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 연결'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
