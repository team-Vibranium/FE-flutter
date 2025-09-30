import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarCustomizeScreen extends StatefulWidget {
  final int initialPoints;
  final String initialAvatar;
  final Function(int points, String avatar)? onAvatarChanged;

  const AvatarCustomizeScreen({
    super.key,
    this.initialPoints = 1250,
    this.initialAvatar = 'default',
    this.onAvatarChanged,
  });

  @override
  State<AvatarCustomizeScreen> createState() => _AvatarCustomizeScreenState();
}

class _AvatarCustomizeScreenState extends State<AvatarCustomizeScreen> {
  late int _userPoints;
  late String _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _userPoints = widget.initialPoints;
    _selectedAvatar = widget.initialAvatar;
    _loadLocalAvatarCache();
  }

  // 아바타 데이터 (더미)
  final List<Map<String, dynamic>> _avatars = [
    {
      'id': 'default',
      'name': '기본 아바타',
      'price': 0,
      'isOwned': true,
      'icon': Icons.person,
      'color': Colors.blue,
    },
    {
      'id': 'cat',
      'name': '고양이',
      'price': 100,
      'isOwned': false,
      'icon': Icons.pets,
      'color': Colors.orange,
    },
    {
      'id': 'robot',
      'name': '로봇',
      'price': 200,
      'isOwned': false,
      'icon': Icons.smart_toy,
      'color': Colors.grey,
    },
    {
      'id': 'star',
      'name': '별',
      'price': 300,
      'isOwned': false,
      'icon': Icons.star,
      'color': Colors.yellow,
    },
    {
      'id': 'heart',
      'name': '하트',
      'price': 150,
      'isOwned': true,
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    {
      'id': 'diamond',
      'name': '다이아몬드',
      'price': 500,
      'isOwned': false,
      'icon': Icons.diamond,
      'color': Colors.cyan,
    },
    {
      'id': 'crown',
      'name': '왕관',
      'price': 800,
      'isOwned': false,
      'icon': Icons.workspace_premium,
      'color': Colors.amber,
    },
    {
      'id': 'rainbow',
      'name': '무지개',
      'price': 1000,
      'isOwned': false,
      'icon': Icons.auto_awesome,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아바타 꾸미기'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          // 포인트 표시
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_userPoints',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 현재 선택된 아바타 미리보기
          _buildCurrentAvatarPreview(),
          
          // 아바타 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final avatar = _avatars[index];
                return _buildAvatarCard(avatar);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadLocalAvatarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('selectedAvatar');
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _selectedAvatar = cached;
        });
      }
    } catch (_) {}
  }

  Widget _buildCurrentAvatarPreview() {
    final currentAvatar = _avatars.firstWhere(
      (avatar) => avatar['id'] == _selectedAvatar,
      orElse: () => _avatars.first,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '현재 아바타',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white.withOpacity(0.9),
              child: Icon(
                currentAvatar['icon'],
                size: 60,
                color: currentAvatar['color'],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentAvatar['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(Map<String, dynamic> avatar) {
    final isSelected = avatar['id'] == _selectedAvatar;

    return Card(
      elevation: isSelected ? 8 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _applyAvatar(avatar['id'] as String),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아바타 아이콘
              CircleAvatar(
                radius: 40,
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Colors.grey[100],
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(
                    avatar['icon'],
                    size: 40,
                    color: avatar['color'],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 아바타 이름
              Text(
                avatar['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // 적용 라벨
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[100] : Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSelected ? '선택됨' : '탭하여 적용',
                  style: TextStyle(
                    color: isSelected ? Colors.green : Colors.blueGrey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyAvatar(String avatarId) async {
    try {
      final api = ApiService();
      final resp = await api.user.updateMyInfo({'selectedAvatar': avatarId});
      if (!mounted) return;
      if (resp.success == true) {
        setState(() {
          _selectedAvatar = avatarId;
        });
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selectedAvatar', avatarId);
        } catch (_) {}
        widget.onAvatarChanged?.call(_userPoints, _selectedAvatar);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아바타가 적용되었습니다'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, avatarId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아바타 적용 실패'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 구매/포인트 로직 제거 (서버는 현재 아바타만 저장)
}
