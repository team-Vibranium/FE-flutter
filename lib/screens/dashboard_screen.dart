import 'package:flutter/material.dart';
import 'alarm_add_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'call_history_screen.dart';
import 'avatar_customize_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final bool _hasAlarms = true; // 더미 데이터
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _switchAnimationController;
  late Animation<double> _switchAnimation;
  
  // 사용자 데이터
  int _userPoints = 1250;
  String _selectedAvatar = 'default';
  
  // 알람 타입 필터 (0: 전체, 1: 일반알람, 2: 전화알람)
  int _alarmTypeFilter = 0;
  

  // 더미 알람 데이터
  final List<Map<String, dynamic>> _alarms = [
    {
      'id': 1,
      'time': '07:00',
      'days': ['월', '화', '수', '목', '금'],
      'type': '일반알람',
      'isEnabled': true,
      'tag': '운동',
      'successRate': 85, // 최근 7일 성공률
    },
    {
      'id': 2,
      'time': '08:30',
      'days': ['토', '일'],
      'type': '전화알람',
      'isEnabled': false,
      'tag': '회의',
      'successRate': 60,
    },
    {
      'id': 3,
      'time': '06:45',
      'days': ['월', '수', '금'],
      'type': '일반알람',
      'isEnabled': true,
      'tag': '독서',
      'successRate': 90,
    },
  ];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AningCall'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlarmAddScreen(
                      onAlarmSaved: (newAlarm) {
                        setState(() {
                          _alarms.add(newAlarm);
                        });
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

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildAlarmTab();
      case 1:
        return const StatsScreen();
      case 2:
        return const CallHistoryScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildAlarmTab();
    }
  }

  Widget _buildAlarmTab() {
    if (!_hasAlarms) {
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
        _buildNextAlarmSummary(),
        
        // 알람 타입 필터 슬라이더
        _buildAlarmTypeSlider(),
        
        // 알람 리스트
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _getFilteredAndSortedAlarms().length,
                itemBuilder: (context, index) {
                  final alarm = _getFilteredAndSortedAlarms()[index];
                  final originalIndex = _alarms.indexOf(alarm);
                  return _buildAnimatedAlarmCard(alarm, originalIndex, index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNextAlarmSummary() {
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
                    initialPoints: _userPoints,
                    initialAvatar: _selectedAvatar,
                    onAvatarChanged: (points, avatar) {
                      setState(() {
                        _userPoints = points;
                        _selectedAvatar = avatar;
                      });
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
                child: _getAvatarIcon(_selectedAvatar),
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

  Widget _buildAlarmTypeSlider() {
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
                        setState(() {
                          _alarmTypeFilter = 0;
                        });
                        _animationController.forward().then((_) {
                          _animationController.reset();
                        });
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _alarmTypeFilter == 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '전체',
                            style: TextStyle(
                              color: _alarmTypeFilter == 0
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
                        setState(() {
                          _alarmTypeFilter = 1;
                        });
                        _animationController.forward().then((_) {
                          _animationController.reset();
                        });
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _alarmTypeFilter == 1
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '일반알람',
                            style: TextStyle(
                              color: _alarmTypeFilter == 1
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
                        setState(() {
                          _alarmTypeFilter = 2;
                        });
                        _animationController.forward().then((_) {
                          _animationController.reset();
                        });
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _alarmTypeFilter == 2
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '전화알람',
                            style: TextStyle(
                              color: _alarmTypeFilter == 2
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

  List<Map<String, dynamic>> _getFilteredAndSortedAlarms() {
    List<Map<String, dynamic>> filteredAlarms = List.from(_alarms);
    
    // 알람 타입 필터링
    if (_alarmTypeFilter == 1) {
      // 일반알람만
      filteredAlarms = _alarms.where((alarm) => alarm['type'] == '일반알람').toList();
    } else if (_alarmTypeFilter == 2) {
      // 전화알람만
      filteredAlarms = _alarms.where((alarm) => alarm['type'] == '전화알람').toList();
    }
    
    // 활성화된 알람을 먼저, 그 다음 비활성화된 알람 순으로 정렬
    filteredAlarms.sort((a, b) {
      if (a['isEnabled'] == b['isEnabled']) return 0;
      return a['isEnabled'] ? -1 : 1;
    });
    
    return filteredAlarms;
  }

  Widget _buildAnimatedAlarmCard(Map<String, dynamic> alarm, int originalIndex, int displayIndex) {
    // 남은 시간 계산 (더미 데이터)
    final remainingTime = _getRemainingTime(alarm['time']);
    
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
                          alarmData: alarm,
                          onAlarmSaved: (updatedAlarm) {
                            setState(() {
                              final index = _alarms.indexWhere((a) => a['id'] == updatedAlarm['id']);
                              if (index != -1) {
                                _alarms[index] = updatedAlarm;
                              }
                            });
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
                              backgroundColor: alarm['isEnabled'] 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[400],
                              radius: 24,
                              child: Text(
                                alarm['time'].split(':')[0],
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
                                    alarm['time'],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: alarm['isEnabled'] 
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
                              value: alarm['isEnabled'],
                              onChanged: (value) {
                                // 스위치 애니메이션 시작
                                _switchAnimationController.forward().then((_) {
                                  _switchAnimationController.reverse();
                                });
                                
                                setState(() {
                                  _alarms[originalIndex]['isEnabled'] = value;
                                });
                                
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
                              alarm['days'].join(', '),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              alarm['type'],
                              style: TextStyle(
                                color: alarm['type'] == '전화알람'
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
                            color: alarm['isEnabled']
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            alarm['tag'],
                            style: TextStyle(
                              color: alarm['isEnabled']
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
