import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_call_service.dart';
import '../core/widgets/buttons/call_button.dart';
import '../core/design_system/app_spacing.dart';
import '../core/design_system/app_radius.dart';

/// AI 통화 화면
/// OpenAI Realtime API와 WebRTC를 활용한 AI 음성 통화 인터페이스
class AICallScreen extends StatefulWidget {
  final String alarmTitle;
  final int? alarmId;
  final VoidCallback? onCallEnded;
  final VoidCallback? onAlarmDismissed;

  const AICallScreen({
    super.key,
    required this.alarmTitle,
    this.alarmId,
    this.onCallEnded,
    this.onAlarmDismissed,
  });

  @override
  State<AICallScreen> createState() => _AICallScreenState();
}

class _AICallScreenState extends State<AICallScreen>
    with TickerProviderStateMixin {
  
  // 서비스
  final AICallService _callService = AICallService();
  
  // 애니메이션 컨트롤러
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _fadeController;
  
  // 애니메이션
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _fadeAnimation;
  
  // 상태
  AICallState _currentState = AICallState.idle;
  String _statusMessage = '';
  String _transcript = '';
  bool _showTranscript = false;
  
  // UI 설정
  static const Duration _animationDuration = Duration(milliseconds: 1000);
  static const Duration _waveAnimationDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupEventListeners();
    _startCall();
  }

  /// 애니메이션 초기화
  void _initializeAnimations() {
    // 펄스 애니메이션 (AI 아바타)
    _pulseController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 웨이브 애니메이션 (음성 파형)
    _waveController = AnimationController(
      duration: _waveAnimationDuration,
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    // 페이드 애니메이션 (상태 메시지)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  /// 이벤트 리스너 설정
  void _setupEventListeners() {
    // AI 통화 상태 변경 리스너
    _callService.eventStream.listen((event) {
      if (mounted) {
        setState(() {
          _currentState = event.state;
          _statusMessage = event.message ?? '';
        });
        
        _updateAnimations(event.state);
        _fadeController.forward().then((_) => _fadeController.reverse());
      }
    });

    // 대화 내용 리스너
    _callService.transcriptStream.listen((transcript) {
      if (mounted) {
        setState(() {
          _transcript = transcript;
          _showTranscript = transcript.isNotEmpty;
        });
      }
    });
  }

  /// 상태별 애니메이션 업데이트
  void _updateAnimations(AICallState state) {
    switch (state) {
      case AICallState.connected:
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        break;
      case AICallState.speaking:
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        break;
      case AICallState.listening:
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        break;
      case AICallState.processing:
        _pulseController.repeat(reverse: true);
        _waveController.stop();
        break;
      case AICallState.error:
      case AICallState.ended:
        _pulseController.stop();
        _waveController.stop();
        break;
      default:
        break;
    }
  }

  /// AI 통화 시작
  Future<void> _startCall() async {
    // 권한 체크 및 요청
    final hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      return; // 권한이 없으면 통화를 시작하지 않음
    }

    // 시스템 UI 숨기기 (몰입형 모드)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // 화면 밝기 최대로 설정
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));

    final success = await _callService.startCall(
      widget.alarmTitle,
      alarmId: widget.alarmId,
    );
    if (!success) {
      _showErrorDialog('AI 통화를 시작할 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // 상태 헤더
              _buildStatusHeader(),
              
              const SizedBox(height: AppSpacing.xl),
              
              // AI 아바타 및 파형
              Expanded(
                flex: 2,
                child: _buildAIAvatar(),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // 알람 정보
              _buildAlarmInfo(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // 대화 내용
              if (_showTranscript) _buildTranscript(),
              
              const Spacer(),
              
              // 통화 컨트롤
              _buildCallControls(),
              
              const SizedBox(height: AppSpacing.lg),
              
              // 알람 해제 버튼
              if (_currentState == AICallState.connected ||
                  _currentState == AICallState.listening)
                _buildDismissAlarmButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 상태 헤더 구성
  Widget _buildStatusHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_currentState) {
      case AICallState.initializing:
        statusColor = Colors.orange;
        statusIcon = Icons.settings;
        statusText = '초기화 중...';
        break;
      case AICallState.connecting:
        statusColor = Colors.blue;
        statusIcon = Icons.wifi_protected_setup;
        statusText = '연결 중...';
        break;
      case AICallState.connected:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'AI와 통화 중';
        break;
      case AICallState.speaking:
        statusColor = Colors.purple;
        statusIcon = Icons.record_voice_over;
        statusText = 'AI가 말하는 중';
        break;
      case AICallState.listening:
        statusColor = Colors.blue;
        statusIcon = Icons.hearing;
        statusText = '듣고 있습니다';
        break;
      case AICallState.processing:
        statusColor = Colors.amber;
        statusIcon = Icons.psychology;
        statusText = '생각하는 중...';
        break;
      case AICallState.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = '오류 발생';
        break;
      case AICallState.ended:
        statusColor = Colors.grey;
        statusIcon = Icons.call_end;
        statusText = '통화 종료됨';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.phone;
        statusText = '대기 중';
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: AppRadius.xl,
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI 아바타 구성
  Widget _buildAIAvatar() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 파형 효과
          if (_currentState == AICallState.speaking ||
              _currentState == AICallState.listening)
            _buildWaveEffect(),
          
          // AI 아바타
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentState == AICallState.connected ||
                       _currentState == AICallState.speaking ||
                       _currentState == AICallState.listening
                    ? _pulseAnimation.value
                    : 1.0,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _getAvatarGradientColors(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getAvatarGradientColors().first.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 상태별 아바타 그라데이션 색상
  List<Color> _getAvatarGradientColors() {
    switch (_currentState) {
      case AICallState.speaking:
        return [Colors.purple, Colors.deepPurple];
      case AICallState.listening:
        return [Colors.blue, Colors.indigo];
      case AICallState.processing:
        return [Colors.amber, Colors.orange];
      case AICallState.error:
        return [Colors.red, Colors.redAccent];
      case AICallState.ended:
        return [Colors.grey, Colors.blueGrey];
      default:
        return [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ];
    }
  }

  /// 파형 효과
  Widget _buildWaveEffect() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 300),
          painter: WavePainter(
            animation: _waveAnimation.value,
            color: _getAvatarGradientColors().first.withOpacity(0.3),
          ),
        );
      },
    );
  }

  /// 알람 정보
  Widget _buildAlarmInfo() {
    return Column(
      children: [
        Text(
          widget.alarmTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'AI와 대화하여 완전히 깨어나세요',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 대화 내용 표시
  Widget _buildTranscript() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 120),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: AppRadius.md,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: SingleChildScrollView(
        child: Text(
          _transcript.isEmpty ? '대화 내용이 여기에 표시됩니다...' : _transcript,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// 통화 컨트롤
  Widget _buildCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 음소거 버튼
        CallButton(
          icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
          backgroundColor: _callService.isMuted 
              ? Colors.red 
              : Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
          size: 60,
          onPressed: _toggleMute,
        ),
        
        // 통화 종료 버튼
        CallButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          iconColor: Colors.white,
          size: 80,
          onPressed: _endCall,
        ),
        
        // 스피커 버튼
        CallButton(
          icon: _callService.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
          backgroundColor: _callService.isSpeakerOn
              ? Colors.blue
              : Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
          size: 60,
          onPressed: _toggleSpeaker,
        ),
      ],
    );
  }

  /// 알람 해제 버튼
  Widget _buildDismissAlarmButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _requestAlarmDismissal,
        icon: const Icon(Icons.alarm_off),
        label: const Text(
          '알람 해제 요청',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.md,
          ),
        ),
      ),
    );
  }

  /// 음소거 토글
  void _toggleMute() {
    _callService.toggleMute();
    setState(() {});
    
    // 햅틱 피드백
    HapticFeedback.selectionClick();
  }

  /// 스피커 토글
  void _toggleSpeaker() {
    _callService.toggleSpeaker();
    setState(() {});
    
    // 햅틱 피드백
    HapticFeedback.selectionClick();
  }

  /// 알람 해제 요청
  Future<void> _requestAlarmDismissal() async {
    // 햅틱 피드백
    HapticFeedback.mediumImpact();
    
    final canDismiss = await _callService.requestAlarmDismissal();
    
    if (canDismiss) {
      // 계측 로그: 해제 가능 판단 지점
      debugPrint('AICallScreen: requestAlarmDismissal -> canDismiss=true');
      _showAlarmDismissDialog();
    } else {
      debugPrint('AICallScreen: requestAlarmDismissal -> canDismiss=false');
      _showMessage('아직 완전히 깨어있지 않은 것 같아요. 조금 더 대화해보세요!');
    }
  }

  /// 통화 종료
  Future<void> _endCall() async {
    // 햅틱 피드백
    HapticFeedback.heavyImpact();
    debugPrint('AICallScreen: endCall triggered (source=explicit)');
    
    await _callService.endCall();
    
    // 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    if (mounted) {
      widget.onCallEnded?.call();
      Navigator.of(context).pop();
    }
  }

  /// 알람 해제 확인 다이얼로그
  void _showAlarmDismissDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '알람 해제',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'AI가 당신이 완전히 깨어있다고 판단했습니다.\n알람을 해제하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('계속 대화하기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAlarmDismissed?.call();
              debugPrint('AICallScreen: endCall triggered (source=dismiss dialog confirm)');
              _endCall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('알람 해제'),
          ),
        ],
      ),
    );
  }

  /// 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '오류',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              debugPrint('AICallScreen: endCall triggered (source=error dialog confirm)');
              _endCall();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 메시지 표시
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 권한 체크 및 요청
  Future<bool> _checkAndRequestPermissions() async {
    // 마이크 권한 상태 확인 (필수)
    final microphoneStatus = await Permission.microphone.status;

    // 마이크 권한이 이미 허용되어 있다면 바로 진행
    if (microphoneStatus.isGranted) {
      return true;
    }

    // 권한 요청 알러트 표시
    final shouldRequest = await _showPermissionAlert();
    if (!shouldRequest) {
      _navigateBack();
      return false;
    }

    // 마이크 권한 요청 (카메라는 선택사항)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    // 마이크 권한만 필수, 카메라는 선택사항
    if (!micGranted) {
      await _showPermissionDeniedDialog();
      _navigateBack();
      return false;
    }

    return true;
  }

  /// 권한 요청 알러트 표시
  Future<bool> _showPermissionAlert() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic, color: Colors.blue),
              SizedBox(width: 8),
              Text('권한 허용 필요'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 통화를 위해 다음 권한이 필요합니다:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.mic, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('마이크: 음성 인식 및 통화'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.camera_alt, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('카메라: 화상 통화 (선택사항)'),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '권한을 허용하시겠습니까?',
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('허용'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// 권한 거부 시 안내 다이얼로그
  Future<void> _showPermissionDeniedDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('권한 필요'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('AI 통화를 사용하려면 마이크 권한이 필요합니다.'),
              SizedBox(height: 12),
              Text(
                '설정 > 개인정보 보호 및 보안 > 마이크에서 권한을 허용해주세요.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // 앱 설정으로 이동
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  /// 이전 화면으로 돌아가기
  void _navigateBack() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    // 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // 애니메이션 컨트롤러 해제
    _pulseController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    
    super.dispose();
  }
}

/// 파형 그리기를 위한 CustomPainter
class WavePainter extends CustomPainter {
  final double animation;
  final Color color;

  WavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 여러 개의 동심원 그리기
    for (int i = 1; i <= 3; i++) {
      final radius = (maxRadius * i / 3) * (0.5 + 0.5 * animation);
      final opacity = (1.0 - animation) * (1.0 - i * 0.2);
      
      paint.color = color.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.color != color;
  }
}
