import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/models/api_models.dart';
import '../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // API 데이터 상태
  bool _isLoading = true;
  String? _error;
  
  // 사용자 정보
  User? _user;
  Map<String, dynamic>? _statisticsSummary;
  Map<String, dynamic>? _pointSummary;
  List<Map<String, dynamic>> _achievements = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// 프로필 데이터 로드
  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authState = ref.read(authStateProvider);
      if (authState.user == null) {
        throw Exception('사용자 정보가 없습니다');
      }

      final apiService = ApiService();
      
      // 병렬로 데이터 로드
      final results = await Future.wait([
        apiService.statistics.getStatisticsSummary(),
        apiService.points.getPointBalance(),
        Future.value(authState.user), // 현재 사용자 정보
      ]);

      if (mounted) {
        setState(() {
          _user = results[2] as User;
          _statisticsSummary = (results[0] as ApiResponse).success ? (results[0] as ApiResponse).data as Map<String, dynamic>? : null;
          _pointSummary = (results[1] as ApiResponse).success ? (results[1] as ApiResponse).data as Map<String, dynamic>? : null;
          
          // 업적 데이터 생성 (실제 데이터 기반)
          _achievements = _generateAchievements();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('프로필 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 실제 데이터 기반으로 업적 생성
  List<Map<String, dynamic>> _generateAchievements() {
    final totalPoints = _pointSummary?['totalPoints'] ?? 0;
    final successRate = _statisticsSummary?['successRate'] ?? 0.0;
    final consecutiveDays = _statisticsSummary?['consecutiveDays'] ?? 0;
    
    return [
      {
        'title': '연속 10일 성공',
        'description': '10일 연속으로 알람을 성공했습니다',
        'isUnlocked': consecutiveDays >= 10,
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
      },
      {
        'title': '포인트 1000 달성',
        'description': '총 포인트 1000점을 달성했습니다',
        'isUnlocked': totalPoints >= 1000,
        'icon': Icons.stars,
        'color': Colors.blue,
      },
      {
        'title': '성공률 마스터',
        'description': '알람 성공률 90% 이상을 달성했습니다',
        'isUnlocked': successRate >= 0.9,
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
      {
        'title': '연속 30일 성공',
        'description': '30일 연속으로 알람을 성공했습니다',
        'isUnlocked': consecutiveDays >= 30,
        'icon': Icons.calendar_month,
        'color': Colors.purple,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('프로필'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('프로필'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류가 발생했습니다\n$_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfileData,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildStatsSummary(),
            const SizedBox(height: 16),
            _buildMenuSection(),
            const SizedBox(height: 16),
            _buildAchievementsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // 프로필 서클 누르면 캐릭터 꾸미기로 이동
                    Navigator.pushNamed(context, '/avatar_customize');
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          (_user?.nickname ?? 'U')[0],
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _user?.nickname ?? '사용자',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber[300]!, Colors.amber[600]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _pointSummary?['currentGrade'] ?? 'BRONZE',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? 'email@example.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _editProfile,
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  tooltip: '프로필 수정',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '나의 성과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // 통계 화면으로 이동
                  },
                  child: const Text('더보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('총 포인트', '${_pointSummary?['totalPoints'] ?? 0}', Icons.stars, Colors.blue),
                ),
                Expanded(
                  child: _buildStatItem('연속일', '${_statisticsSummary?['consecutiveDays'] ?? 0}일', Icons.local_fire_department, Colors.orange),
                ),
                Expanded(
                  child: _buildStatItem('성공률', '${((_statisticsSummary?['successRate'] ?? 0.0) * 100).round()}%', Icons.trending_up, Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Card(
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.alarm,
            title: '알람 설정',
            onTap: _alarmSettings,
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.help,
            title: '도움말',
            onTap: _showHelp,
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.info,
            title: '앱 정보',
            onTap: _showAppInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildAchievementsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '업적',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._achievements.map((achievement) => _buildAchievementItem(achievement)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['isUnlocked'] as bool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? achievement['color'].withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              achievement['icon'],
              color: isUnlocked 
                  ? achievement['color']
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked 
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnlocked 
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(
              Icons.check_circle,
              color: achievement['color'],
              size: 24,
            )
          else
            Icon(
              Icons.lock,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
        ],
      ),
    );
  }


  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('로그아웃'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                '회원탈퇴',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteAccount();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '프로필 수정',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('닉네임 변경'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _changeNickname();
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('비밀번호 변경'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _changePassword();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('알림 설정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _notificationSettings();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _changeNickname() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: const Text('닉네임 변경 기능은 추후 구현됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: const Text('비밀번호 변경 기능은 추후 구현됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _alarmSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알람 설정'),
        content: const Text('알람 설정 기능은 추후 구현됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _notificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 설정'),
        content: const Text('알림 설정 기능은 추후 구현됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('도움말'),
        content: const Text('도움말 기능은 추후 구현됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 정보'),
        content: const Text('AningCall v1.0.0\n알람 앱'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 로그아웃 로직
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말 회원 탈퇴하시겠습니까?\n모든 데이터가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 회원 탈퇴 로직
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }
}
