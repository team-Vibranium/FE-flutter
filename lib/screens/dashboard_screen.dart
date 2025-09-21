import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'alarm_add_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'call_history_screen.dart';
import 'avatar_customize_screen.dart';
import '../core/providers/dashboard_provider.dart';
import '../core/models/alarm.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _switchAnimationController;
  late Animation<double> _switchAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _switchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _switchAnimation = CurvedAnimation(
      parent: _switchAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _switchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AningCall'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _buildBody(dashboardState),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: dashboardState.currentIndex,
        onTap: (index) {
          ref.read(dashboardProvider.notifier).setCurrentIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: '알람',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '통계',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '통화기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
      floatingActionButton: dashboardState.currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlarmAddScreen(
                      onAlarmSaved: (alarm) {
                        // Map을 Alarm 객체로 변환
                        final alarmObj = Alarm(
                          id: alarm['id'] ?? DateTime.now().millisecondsSinceEpoch,
                          time: alarm['time'] ?? '07:00',
                          days: List<String>.from(alarm['days'] ?? ['월', '화', '수', '목', '금']),
                          type: alarm['type'] == '전화알람' ? AlarmType.call : AlarmType.normal,
                          isEnabled: alarm['isEnabled'] ?? true,
                          tag: alarm['tag'] ?? '알람',
                          successRate: alarm['successRate'] ?? 0,
                        );
                        ref.read(dashboardProvider.notifier).addAlarm(alarmObj);
                        // 애니메이션 시작
                        _animationController.forward().then((_) {
                          _animationController.reset();
                        });
                      },
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(DashboardState state) {
    switch (state.currentIndex) {
      case 0:
        return _buildAlarmTab(state);
      case 1:
        return const StatsScreen();
      case 2:
        return const CallHistoryScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildAlarmTab(state);
    }
  }

  Widget _buildAlarmTab(DashboardState state) {
    if (state.alarms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '알람 없으면 텅텅…',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 다음 알람 요약 카드
        _buildNextAlarmSummary(state),
        
        // 알람 타입 필터 슬라이더
        _buildAlarmTypeSlider(state),
        
        // 알람 리스트
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ref.read(dashboardProvider.notifier).getFilteredAndSortedAlarms().length,
                itemBuilder: (context, index) {
                  final alarm = ref.read(dashboardProvider.notifier).getFilteredAndSortedAlarms()[index];
                  final originalIndex = state.alarms.indexOf(alarm);
                  return _buildAnimatedAlarmCard(alarm, originalIndex, index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNextAlarmSummary(DashboardState state) {
    // 다음 알람까지 남은 시간 계산 (더미 데이터)
    const nextAlarmTime = '6시간 20분';
    const todayAlarmCount = 2;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽: 알람 요약 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '다음 알람까지 남은 시간: $nextAlarmTime',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 오늘 알람 개수
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '오늘 알람 $todayAlarmCount개',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 오른쪽: 사용자 아바타
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AvatarCustomizeScreen(
                    initialPoints: state.userPoints,
                    initialAvatar: state.selectedAvatar,
                    onAvatarChanged: (points, avatar) {
                      ref.read(dashboardProvider.notifier).updateUserProfile(
                        points: points,
                        avatar: avatar,
                      );
                    },
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: _getAvatarIcon(state.selectedAvatar),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRemainingTime(String alarmTime) {
    // 더미 데이터로 남은 시간 반환
    final timeMap = {
      '07:00': '6시간 20분 후',
      '08:30': '7시간 50분 후',
      '06:45': '6시간 5분 후',
    };
    return timeMap[alarmTime] ?? '시간 계산 중...';
  }

  Widget _getAvatarIcon(String avatarId) {
    // 아바타 ID에 따른 아이콘 반환
    final avatarMap = {
      'default': Icons.person,
      'cat': Icons.pets,
      'robot': Icons.smart_toy,
      'star': Icons.star,
      'heart': Icons.favorite,
      'diamond': Icons.diamond,
      'crown': Icons.workspace_premium,
      'rainbow': Icons.auto_awesome,
    };

    final colorMap = {
      'default': Theme.of(context).colorScheme.primary,
      'cat': Colors.orange,
      'robot': Colors.grey,
      'star': Colors.yellow,
      'heart': Colors.red,
      'diamond': Colors.cyan,
      'crown': Colors.amber,
      'rainbow': Colors.purple,
    };

    return Icon(
      avatarMap[avatarId] ?? Icons.person,
      size: 55,
      color: colorMap[avatarId] ?? Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildAlarmTypeSlider(DashboardState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(dashboardProvider.notifier).setAlarmTypeFilter(0);
                        _animationController.forward().then((_) {
                          _animationController.reset();
                        });
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: state.alarmTypeFilter == 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '전체',
                            style: TextStyle(
                              color: state.alarmTypeFilter == 0
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(dashboardProvider.notifier).setAlarmTypeFilter(1);
                        _animationController.forward().then((_) {
                          _animationController.reset();
                        });
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: state.alarmTypeFilter == 1
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '일반알람',
                            style: TextStyle(
                              color: state.alarmTypeFilter == 1
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(dashboardProvider.notifier).setAlarmTypeFilter(2);
                        _animationController.forward().then((_) {
                          _animationController.reset();
                        });
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: state.alarmTypeFilter == 2
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '전화알람',
                            style: TextStyle(
                              color: state.alarmTypeFilter == 2
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAlarmCard(Alarm alarm, int originalIndex, int displayIndex) {
    // 남은 시간 계산 (더미 데이터)
    final remainingTime = _getRemainingTime(alarm.time);
    
    return AnimatedBuilder(
      animation: _switchAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -0.1), // 위로 살짝 슬라이드
          ).animate(CurvedAnimation(
            parent: _switchAnimation,
            curve: Curves.easeInOut,
          )),
          child: Transform.scale(
            scale: 1.0 + (_switchAnimation.value * 0.02), // 약간의 스케일 효과
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmAddScreen(
                          alarmData: alarm.toJson(),
                          onAlarmSaved: (updatedAlarm) {
                            // Map을 Alarm 객체로 변환
                            final updatedAlarmObj = Alarm(
                              id: updatedAlarm['id'] ?? alarm.id,
                              time: updatedAlarm['time'] ?? alarm.time,
                              days: List<String>.from(updatedAlarm['days'] ?? alarm.days),
                              type: updatedAlarm['type'] == '전화알람' ? AlarmType.call : AlarmType.normal,
                              isEnabled: updatedAlarm['isEnabled'] ?? alarm.isEnabled,
                              tag: updatedAlarm['tag'] ?? alarm.tag,
                              successRate: updatedAlarm['successRate'] ?? alarm.successRate,
                            );
                            ref.read(dashboardProvider.notifier).updateAlarm(updatedAlarmObj);
                            // 애니메이션 시작
                            _animationController.forward().then((_) {
                              _animationController.reset();
                            });
                          },
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 시간 표시
                            CircleAvatar(
                              backgroundColor: alarm.isEnabled 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[400],
                              radius: 24,
                              child: Text(
                                alarm.time.split(':')[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // 시간과 남은 시간
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alarm.time,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: alarm.isEnabled 
                                          ? null 
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remainingTime,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // ON/OFF 스위치
                            Switch(
                              value: alarm.isEnabled,
                              onChanged: (value) {
                                // 스위치 애니메이션 시작
                                _switchAnimationController.forward().then((_) {
                                  _switchAnimationController.reverse();
                                });
                                
                                ref.read(dashboardProvider.notifier).toggleAlarm(alarm.id);
                                
                                // 위치 변경 애니메이션 시작
                                Future.delayed(const Duration(milliseconds: 150), () {
                                  _animationController.forward().then((_) {
                                    _animationController.reset();
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 요일과 유형
                        Row(
                          children: [
                            Text(
                              alarm.days.join(', '),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              alarm.typeDisplayName,
                              style: TextStyle(
                                color: alarm.type == AlarmType.call
                                    ? Colors.blue[600]
                                    : Colors.green[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // 태그
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: alarm.isEnabled
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            alarm.tag,
                            style: TextStyle(
                              color: alarm.isEnabled
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}