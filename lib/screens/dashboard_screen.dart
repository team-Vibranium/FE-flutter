import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'alarm_add_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'call_history_screen.dart';
import 'avatar_customize_screen.dart';
import '../core/providers/dashboard_provider.dart';
import '../core/models/alarm.dart';
import '../core/widgets/buttons/theme_toggle_button.dart';

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
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
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
        
        // 알람 리스트 (최소 3개 표시)
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final filteredAlarms = ref.read(dashboardProvider.notifier).getFilteredAndSortedAlarms();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredAlarms.length,
                itemBuilder: (context, index) {
                  final alarm = filteredAlarms[index];
                  final originalIndex = state.alarms.indexOf(alarm);
                  return _buildCompactAlarmCard(alarm, originalIndex, index);
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
    final todayAlarmCount = ref.read(dashboardProvider.notifier).getFilteredAndSortedAlarms().length;
    final activeAlarmCount = state.alarms.where((alarm) => alarm.isEnabled).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8), // 상하 마진 줄임
      padding: const EdgeInsets.all(16), // 패딩 줄임
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
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
                
                // 알람 상태 정보
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '활성 ${activeAlarmCount}개',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '전체 $todayAlarmCount개',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
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
              radius: 45, // 크기 줄임
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: CircleAvatar(
                radius: 40, // 크기 줄임
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: _getAvatarIcon(state.selectedAvatar, size: 45), // 크기 조정
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

  Widget _getAvatarIcon(String avatarId, {double size = 55}) {
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
      size: size,
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

  Widget _buildCompactAlarmCard(Alarm alarm, int originalIndex, int displayIndex) {
    // 남은 시간 계산 (더미 데이터)
    final remainingTime = _getRemainingTime(alarm.time);
    
    return AnimatedBuilder(
      animation: _switchAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -0.1),
          ).animate(CurvedAnimation(
            parent: _switchAnimation,
            curve: Curves.easeInOut,
          )),
          child: Transform.scale(
            scale: 1.0 + (_switchAnimation.value * 0.02),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.only(bottom: 8), // 마진 줄임
              child: Card(
                elevation: 2, // 그림자 줄임
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 둥글기 줄임
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmAddScreen(
                          alarmData: alarm.toJson(),
                          onAlarmSaved: (updatedAlarm) {
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
                            _animationController.forward().then((_) {
                              _animationController.reset();
                            });
                          },
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12), // 패딩 줄임
                    child: Row(
                      children: [
                        // 시간 표시 (더 작게)
                        CircleAvatar(
                          backgroundColor: alarm.isEnabled 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400],
                          radius: 18, // 크기 줄임
                          child: Text(
                            alarm.time.split(':')[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // 폰트 크기 줄임
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // 메인 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    alarm.time,
                                    style: TextStyle(
                                      fontSize: 18, // 폰트 크기 줄임
                                      fontWeight: FontWeight.bold,
                                      color: alarm.isEnabled 
                                          ? null 
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: alarm.type == AlarmType.call
                                          ? Colors.blue[100]
                                          : Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      alarm.type == AlarmType.call ? '전화' : '일반',
                                      style: TextStyle(
                                        color: alarm.type == AlarmType.call
                                            ? Colors.blue[700]
                                            : Colors.green[700],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alarm.days.length >= 5 
                                          ? '평일' 
                                          : alarm.days.join(', '),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (alarm.tag.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: alarm.isEnabled
                                            ? Theme.of(context).colorScheme.primaryContainer
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        alarm.tag,
                                        style: TextStyle(
                                          color: alarm.isEnabled
                                              ? Theme.of(context).colorScheme.onPrimaryContainer
                                              : Colors.grey[600],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // 스위치 (더 작게)
                        Transform.scale(
                          scale: 0.8, // 스위치 크기 줄임
                          child: Switch(
                            value: alarm.isEnabled,
                            onChanged: (value) {
                              _switchAnimationController.forward().then((_) {
                                _switchAnimationController.reverse();
                              });
                              
                              ref.read(dashboardProvider.notifier).toggleAlarm(alarm.id);
                              
                              Future.delayed(const Duration(milliseconds: 150), () {
                                _animationController.forward().then((_) {
                                  _animationController.reset();
                                });
                              });
                            },
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