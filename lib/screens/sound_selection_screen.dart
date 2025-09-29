import 'package:flutter/material.dart';

class SoundSelectionScreen extends StatefulWidget {
  final String currentSound;
  
  const SoundSelectionScreen({super.key, required this.currentSound});

  @override
  State<SoundSelectionScreen> createState() => _SoundSelectionScreenState();
}

class _SoundSelectionScreenState extends State<SoundSelectionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSound = '';
  
  // 장르별 음악 데이터
  final Map<String, List<Map<String, dynamic>>> _musicByGenre = {
    '클래식': [
      {'name': '기본 알람음', 'duration': '0:30', 'isPlaying': false},
      {'name': '부드러운 벨', 'duration': '0:45', 'isPlaying': false},
      {'name': '따뜻한 피아노', 'duration': '1:00', 'isPlaying': false},
      {'name': '자연의 소리', 'duration': '2:00', 'isPlaying': false},
      {'name': '모차르트 소나타', 'duration': '1:30', 'isPlaying': false},
      {'name': '바흐 골드베르크', 'duration': '2:15', 'isPlaying': false},
    ],
    '자연': [
      {'name': '새소리', 'duration': '3:00', 'isPlaying': false},
      {'name': '비 소리', 'duration': '4:00', 'isPlaying': false},
      {'name': '바다 소리', 'duration': '5:00', 'isPlaying': false},
      {'name': '숲 소리', 'duration': '3:30', 'isPlaying': false},
      {'name': '폭포 소리', 'duration': '4:30', 'isPlaying': false},
      {'name': '바람 소리', 'duration': '2:45', 'isPlaying': false},
    ],
    '현대음악': [
      {'name': '일렉트로닉', 'duration': '1:20', 'isPlaying': false},
      {'name': '재즈', 'duration': '2:30', 'isPlaying': false},
      {'name': '팝송', 'duration': '3:15', 'isPlaying': false},
      {'name': 'R&B', 'duration': '2:45', 'isPlaying': false},
      {'name': '록', 'duration': '1:50', 'isPlaying': false},
      {'name': '힙합', 'duration': '2:10', 'isPlaying': false},
    ],
    'ASMR': [
      {'name': '잔잔한 말소리', 'duration': '5:00', 'isPlaying': false},
      {'name': '펜 소리', 'duration': '3:45', 'isPlaying': false},
      {'name': '종이 소리', 'duration': '2:30', 'isPlaying': false},
      {'name': '물소리', 'duration': '4:15', 'isPlaying': false},
      {'name': '마사지 소리', 'duration': '6:00', 'isPlaying': false},
      {'name': '호흡 소리', 'duration': '3:20', 'isPlaying': false},
    ],
  };

  final List<String> _genres = ['클래식', '자연', '현대음악', 'ASMR'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _genres.length, vsync: this);
    _selectedSound = widget.currentSound;
    
    // 현재 선택된 음악이 어느 장르에 있는지 찾기
    for (int i = 0; i < _genres.length; i++) {
      if (_musicByGenre[_genres[i]]!.any((music) => music['name'] == _selectedSound)) {
        _tabController.index = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람음 선택'),
        actions: [
          if (_selectedSound.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: const Text(
                '확인',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _genres.map((genre) => Tab(text: genre)).toList(),
          onTap: (index) {
            // 탭 변경 시 추가 로직이 필요하면 여기에 추가
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _genres.map((genre) => _buildMusicList(genre)).toList(),
      ),
    );
  }

  Widget _buildMusicList(String genre) {
    final musicList = _musicByGenre[genre]!;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: musicList.length,
      itemBuilder: (context, index) {
        final music = musicList[index];
        final isSelected = music['name'] == _selectedSound;
        final isPlaying = music['isPlaying'] as bool;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey[300],
              child: Icon(
                isSelected ? Icons.check : Icons.music_note,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            title: Text(
              music['name'],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            subtitle: Text(
              '${music['duration']}',
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _togglePlay(music['name'], genre),
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
            onTap: () => _selectMusic(music['name']),
          ),
        );
      },
    );
  }

  void _selectMusic(String musicName) {
    setState(() {
      _selectedSound = musicName;
    });
  }

  void _togglePlay(String musicName, String genre) {
    bool isPlaying = false;
    
    setState(() {
      // 모든 음악의 재생 상태를 false로 초기화
      for (String g in _genres) {
        for (var music in _musicByGenre[g]!) {
          music['isPlaying'] = false;
        }
      }
      
      // 선택된 음악만 재생 상태로 변경
      final music = _musicByGenre[genre]!.firstWhere((m) => m['name'] == musicName);
      music['isPlaying'] = !music['isPlaying'];
      isPlaying = music['isPlaying'];
    });
    
    if (isPlaying) {
      _showPlayingMessage(musicName);
    }
  }

  void _showPlayingMessage(String musicName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$musicName 재생 중...'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '중지',
          onPressed: () {
            setState(() {
              // 모든 음악의 재생 상태를 false로 초기화
              for (String g in _genres) {
                for (var music in _musicByGenre[g]!) {
                  music['isPlaying'] = false;
                }
              }
            });
          },
        ),
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedSound.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알람음을 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알람음 선택'),
        content: Text('"$_selectedSound"을(를) 선택하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context, _selectedSound); // 이전 화면으로 돌아가면서 선택된 음악 전달
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
