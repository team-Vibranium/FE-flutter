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
  int _consumptionPoints = 0; // 구매에 사용할 소비 포인트
  Set<String> _ownedAvatarIds = <String>{'default'}; // 로컬 캐시 보유 목록

  @override
  void initState() {
    super.initState();
    _userPoints = widget.initialPoints;
    _selectedAvatar = widget.initialAvatar;
    _initData();
  }

  // 아바타 데이터 (로컬 프리셋: 100~800 구간 가격 포함)
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
      'price': 400,
      'isOwned': false,
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
                final isOwned = _ownedAvatarIds.contains(avatar['id']);
                return _buildAvatarCard({...avatar, 'isOwned': isOwned});
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 선택된 아바타 로드
      final cached = prefs.getString('selectedAvatar');
      // 보유 목록 로드
      final owned = prefs.getStringList('ownedAvatars') ?? <String>[];
      // 포인트/등급 잔액 로드 (소비 포인트 사용)
      final pointResp = await ApiService().points.getPointBalance();
      if (!mounted) return;
      setState(() {
        if (cached != null && cached.isNotEmpty) {
          _selectedAvatar = cached;
        }
        _ownedAvatarIds = {'default', ...owned};
        if (pointResp.success && pointResp.data != null) {
          final data = pointResp.data!;
          _consumptionPoints = (data['consumptionPoints'] as int?) ?? 0;
          _userPoints = (data['totalPoints'] as int?) ?? _userPoints;
        }
      });
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
    final bool isOwned = (avatar['isOwned'] as bool?) ?? false;
    final int price = avatar['price'] as int;

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
        onTap: () async {
          final id = avatar['id'] as String;
          if (isOwned || price == 0) {
            await _applyAvatar(id);
          } else {
            _confirmPurchase(id, price, avatar['name'] as String);
          }
        },
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
              
              // 가격/상태
              Text(
                price == 0 ? '무료' : '$price 포인트',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: () async {
                    final id = avatar['id'] as String;
                    if (isOwned || price == 0) {
                      await _applyAvatar(id);
                    } else {
                      _confirmPurchase(id, price, avatar['name'] as String);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned || isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text(
                    isOwned || price == 0 ? (isSelected ? '선택됨' : '적용') : '구매',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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

  Future<void> _confirmPurchase(String avatarId, int price, String name) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아바타 구매'),
        content: Text('"$name" 아바타를 $price 포인트로 구매하시겠습니까?\n(보유 소비 포인트: $_consumptionPoints)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _purchaseAvatar(avatarId, price);
            },
            child: const Text('구매'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseAvatar(String avatarId, int price) async {
    try {
      // 잔액 최신화
      final balanceResp = await ApiService().points.getPointBalance();
      int consumption = _consumptionPoints;
      if (balanceResp.success && balanceResp.data != null) {
        consumption = (balanceResp.data!['consumptionPoints'] as int?) ?? 0;
      }
      if (consumption < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('포인트가 부족합니다'), backgroundColor: Colors.red),
        );
        return;
      }

      // 서버에 구매 기록(소비 포인트 차감) 저장
      final spendResp = await ApiService().points.spendPointsForSkin(skinId: avatarId, price: price);
      if (!spendResp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구매 실패: ${spendResp.message ?? '알 수 없는 오류'}'), backgroundColor: Colors.red),
        );
        return;
      }

      // 로컬 보유 처리 및 포인트 차감 반영
      setState(() {
        _ownedAvatarIds.add(avatarId);
        _consumptionPoints = consumption - price;
        _userPoints = (_userPoints - price).clamp(0, 1 << 31);
      });
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('ownedAvatars', _ownedAvatarIds.toList());
      } catch (_) {}

      // 구매 후 즉시 적용
      await _applyAvatar(avatarId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구매 오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 구매/포인트 로직 제거 (서버는 현재 아바타만 저장)
}
