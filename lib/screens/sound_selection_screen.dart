import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundSelectionScreen extends StatefulWidget {
  final String currentSound;
  
  const SoundSelectionScreen({super.key, required this.currentSound});

  @override
  State<SoundSelectionScreen> createState() => _SoundSelectionScreenState();
}

class _SoundSelectionScreenState extends State<SoundSelectionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSound = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 카테고리별 알람 사운드 데이터
  final Map<String, List<Map<String, dynamic>>> _musicByGenre = {
    '차분한 소리': [
      {'name': '더 자라는 듯한 알람소리', 'file': 'sounds/차분한 소리/더 자라는 듯한 알람소리.mp3', 'isPlaying': false},
      {'name': '동요 소리', 'file': 'sounds/차분한 소리/동요 소리.mp3', 'isPlaying': false},
      {'name': '몽환적인 소리', 'file': 'sounds/차분한 소리/몽환적인 소리.mp3', 'isPlaying': false},
      {'name': '알람이라기엔 좋은 소리', 'file': 'sounds/차분한 소리/알람이라기엔 좋은 소리.mp3', 'isPlaying': false},
    ],
    '전통적인 알람': [
      {'name': '도도동동동', 'file': 'sounds/전통적인 알람/도도동동동.mp3', 'isPlaying': false},
      {'name': '무난한 소리', 'file': 'sounds/전통적인 알람/무난한 소리.mp3', 'isPlaying': false},
      {'name': '뱃고둥 소리', 'file': 'sounds/전통적인 알람/뱃고둥 소리.mp3', 'isPlaying': false},
      {'name': '보드라운 알람', 'file': 'sounds/전통적인 알람/보드라운 알람.mp3', 'isPlaying': false},
      {'name': '알람시계소리', 'file': 'sounds/전통적인 알람/알람시계소리.mp3', 'isPlaying': false},
      {'name': '영화에 나오는 알람소리', 'file': 'sounds/전통적인 알람/영화에 나오는 알람소리.mp3', 'isPlaying': false},
      {'name': '자연이 담긴 소리', 'file': 'sounds/전통적인 알람/자연이 담긴 소리.mp3', 'isPlaying': false},
      {'name': '작은 종 소리', 'file': 'sounds/전통적인 알람/작은 종 소리.mp3', 'isPlaying': false},
    ],
    '리듬감 있는 소리': [
      {'name': '발랄한 소리', 'file': 'sounds/리듬감 있는 소리/발랄한 소리.mp3', 'isPlaying': false},
      {'name': '약간 신나는 소리', 'file': 'sounds/리듬감 있는 소리/약간 신나는 소리.mp3', 'isPlaying': false},
      {'name': '약간 크리스마스', 'file': 'sounds/리듬감 있는 소리/약간 크리스마스.mp3', 'isPlaying': false},
      {'name': '오예 비트', 'file': 'sounds/리듬감 있는 소리/오예 비트.mp3', 'isPlaying': false},
      {'name': '오예 비트2', 'file': 'sounds/리듬감 있는 소리/오예 비트2.mp3', 'isPlaying': false},
      {'name': '오예 비트4', 'file': 'sounds/리듬감 있는 소리/오예 비트4.mp3', 'isPlaying': false},
      {'name': '오예오ㅖ', 'file': 'sounds/리듬감 있는 소리/오예오ㅖ.mp3', 'isPlaying': false},
      {'name': '일렉트로닉', 'file': 'sounds/리듬감 있는 소리/일렉트로닉.mp3', 'isPlaying': false},
      {'name': '흥겨운 비트', 'file': 'sounds/리듬감 있는 소리/흥겨운 비트.mp3', 'isPlaying': false},
    ],
    '긴급알람': [
      {'name': '경보음 소리', 'file': 'sounds/긴급알람/경보음 소리.mp3', 'isPlaying': false},
      {'name': '낮은 사이렌', 'file': 'sounds/긴급알람/낮은 사이렌.mp3', 'isPlaying': false},
      {'name': '아이폰 안전문자', 'file': 'sounds/긴급알람/아이폰 안전문자.mp3', 'isPlaying': false},
      {'name': '아지트 습격 경보', 'file': 'sounds/긴급알람/아지트 습격 경보.mp3', 'isPlaying': false},
      {'name': '안 일어나면 비상', 'file': 'sounds/긴급알람/안 일어나면 비상.mp3', 'isPlaying': false},
      {'name': '이래도 안 일어나', 'file': 'sounds/긴급알람/이래도 안 일어나.mp3', 'isPlaying': false},
      {'name': '지나가다가 잘못 건들이', 'file': 'sounds/긴급알람/지나가다가 잘못 건들이.mp3', 'isPlaying': false},
    ],
    '이상한 소리': [
      {'name': '쀠우우우휘우휘우', 'file': 'sounds/이상한 소리/쀠우우우휘우휘우.mp3', 'isPlaying': false},
      {'name': '삘릴리릴삘릴리릴', 'file': 'sounds/이상한 소리/삘릴리릴삘릴리릴.mp3', 'isPlaying': false},
    ],
  };

  final List<String> _genres = ['차분한 소리', '전통적인 알람', '리듬감 있는 소리', '긴급알람', '이상한 소리'];

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
    _audioPlayer.dispose();
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
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
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
              '탭하여 미리듣기',
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

  void _togglePlay(String musicName, String genre) async {
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
      try {
        // 실제 음성 파일 재생
        final music = _musicByGenre[genre]!.firstWhere((m) => m['name'] == musicName);
        final filePath = music['file'] as String;
        await _audioPlayer.play(AssetSource(filePath));
        
        // 재생 완료 시 상태 업데이트
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              music['isPlaying'] = false;
            });
          }
        });
        
        _showPlayingMessage(musicName);
      } catch (e) {
        final music = _musicByGenre[genre]!.firstWhere((m) => m['name'] == musicName);
        setState(() {
          music['isPlaying'] = false;
        });
        print('오디오 재생 오류: $e');
        print('파일 경로: ${music['file']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('음성 재생 실패: $e\n파일: ${music['file']}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      // 재생 중지
      await _audioPlayer.stop();
    }
  }

  void _showPlayingMessage(String musicName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$musicName 재생 중...'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '중지',
          onPressed: () async {
            await _audioPlayer.stop();
            if (mounted) {
              setState(() {
                // 모든 음악의 재생 상태를 false로 초기화
                for (String g in _genres) {
                  for (var music in _musicByGenre[g]!) {
                    music['isPlaying'] = false;
                  }
                }
              });
            }
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
