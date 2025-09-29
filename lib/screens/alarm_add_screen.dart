import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sound_selection_screen.dart';
import '../core/services/morning_call_alarm_service.dart';
import '../core/services/local_alarm_service.dart';
import '../core/providers/auth_provider.dart';

class AlarmAddScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? alarmData;
  final Function(Map<String, dynamic>)? onAlarmSaved;
  
  const AlarmAddScreen({super.key, this.alarmData, this.onAlarmSaved});

  @override
  ConsumerState<AlarmAddScreen> createState() => _AlarmAddScreenState();
}

class _AlarmAddScreenState extends ConsumerState<AlarmAddScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  String _selectedAlarmType = '일반알람';
  String _selectedMission = '퍼즐';
  String _selectedSound = '기본 알람음';
  String _selectedVoice = '여성 목소리';
  String _selectedConcept = '친근한';
  double _volume = 0.8;
  bool _isVibrationEnabled = true;
  int _snoozeMinutes = 5;
  int _snoozeCount = 3;
  bool _isSoundPlaying = false;
  bool _isVoicePlaying = false;
  
  final List<String> _selectedDays = [];
  final TextEditingController _alarmTitleController = TextEditingController();
  final TextEditingController _situationController = TextEditingController();

  final List<String> _days = ['월', '화', '수', '목', '금', '토', '일'];
  final List<String> _missions = ['퍼즐', '수학 문제', '단어 맞추기', '기억력 테스트'];
  final List<String> _voices = ['여성 목소리', '남성 목소리', '아이 목소리', '할머니 목소리'];
  final List<String> _concepts = ['친근한', '격려하는', '재미있는', '진지한', '따뜻한', '에너지틱한'];
  final List<int> _snoozeMinutesOptions = [5, 10, 15, 30];
  final List<int> _snoozeCountOptions = [1, 2, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    _loadAlarmData();
  }

  void _loadAlarmData() {
    if (widget.alarmData != null) {
      final alarm = widget.alarmData!;
      
      // 시간 설정
      if (alarm['time'] != null) {
        // time 필드가 있는 경우
        final timeParts = alarm['time'].split(':');
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      } else if (alarm['hour'] != null && alarm['minute'] != null) {
        // hour와 minute 필드가 있는 경우
        _selectedTime = TimeOfDay(
          hour: alarm['hour'] as int,
          minute: alarm['minute'] as int,
        );
      } else {
        // 기본값 설정
        _selectedTime = TimeOfDay.now();
      }
      
      // 알람 타입 설정 (enum을 문자열로 변환)
      if (alarm['type'] == 'NORMAL' || alarm['type'] == '일반알람') {
        _selectedAlarmType = '일반알람';
      } else if (alarm['type'] == 'CALL' || alarm['type'] == '전화알람') {
        _selectedAlarmType = '전화알람';
      }
      
      // 요일 설정
      _selectedDays.clear();
      if (alarm['days'] != null) {
        _selectedDays.addAll(List<String>.from(alarm['days']));
      } else if (alarm['repeatDays'] != null) {
        // repeatDays가 숫자 리스트인 경우 (1=월요일, 7=일요일)
        final repeatDays = alarm['repeatDays'] as List<dynamic>?;
        if (repeatDays != null && repeatDays.isNotEmpty) {
          for (final day in repeatDays) {
            if (day is int) {
              switch (day) {
                case 1: _selectedDays.add('월'); break;
                case 2: _selectedDays.add('화'); break;
                case 3: _selectedDays.add('수'); break;
                case 4: _selectedDays.add('목'); break;
                case 5: _selectedDays.add('금'); break;
                case 6: _selectedDays.add('토'); break;
                case 7: _selectedDays.add('일'); break;
              }
            } else if (day is String) {
              _selectedDays.add(day);
            }
          }
        }
      }
      
      // 제목 설정
      if (alarm['title'] != null) {
        _alarmTitleController.text = alarm['title'].toString();
      } else if (alarm['tag'] != null) {
        _alarmTitleController.text = alarm['tag'].toString();
      } else if (alarm['label'] != null) {
        _alarmTitleController.text = alarm['label'].toString();
      } else {
        _alarmTitleController.text = '알람';
      }
      
      // 상황 설정
      if (alarm['situation'] != null) {
        _situationController.text = alarm['situation'].toString();
      } else if (alarm['label'] != null) {
        _situationController.text = alarm['label'].toString();
      }
      
      // 미션 설정
      if (alarm['mission'] != null) {
        _selectedMission = alarm['mission'].toString();
      }
      
      // 사운드 설정
      if (alarm['sound'] != null) {
        _selectedSound = alarm['sound'].toString();
      } else if (alarm['soundPath'] != null) {
        _selectedSound = alarm['soundPath'].toString();
      }
      
      // 목소리 설정
      if (alarm['voice'] != null) {
        _selectedVoice = alarm['voice'].toString();
      }
      
      // 컨셉 설정
      if (alarm['concept'] != null) {
        _selectedConcept = alarm['concept'].toString();
      }
      
      // 볼륨 설정
      if (alarm['volume'] != null) {
        _volume = (alarm['volume'] is double) ? alarm['volume'] : alarm['volume'].toDouble();
      }
      
      // 진동 설정
      if (alarm['isVibrationEnabled'] != null) {
        _isVibrationEnabled = alarm['isVibrationEnabled'] as bool;
      } else if (alarm['vibrate'] != null) {
        _isVibrationEnabled = alarm['vibrate'] as bool;
      }
      
      // 스누즈 설정
      if (alarm['snoozeMinutes'] != null) {
        _snoozeMinutes = alarm['snoozeMinutes'] is int ? alarm['snoozeMinutes'] : int.tryParse(alarm['snoozeMinutes'].toString()) ?? 5;
      } else if (alarm['snoozeInterval'] != null) {
        _snoozeMinutes = alarm['snoozeInterval'] is int ? alarm['snoozeInterval'] : int.tryParse(alarm['snoozeInterval'].toString()) ?? 5;
      }
      
      if (alarm['snoozeCount'] != null) {
        _snoozeCount = alarm['snoozeCount'] is int ? alarm['snoozeCount'] : int.tryParse(alarm['snoozeCount'].toString()) ?? 3;
      }
      
      // 스누즈 활성화 설정은 _snoozeCount로 대체 (0이면 비활성화)
      
    } else {
      // 새 알람일 때 기본값 설정
      _alarmTitleController.text = '새 알람';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarmData != null ? '알람 편집' : '알람 추가'),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: Text(
              widget.alarmData != null ? '수정' : '저장',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlarmTitleInput(),
            const SizedBox(height: 24),
            _buildTimeSelector(),
            const SizedBox(height: 24),
            _buildDaySelector(),
            const SizedBox(height: 24),
            _buildAlarmTypeSelector(),
            const SizedBox(height: 24),
            _buildMissionSelector(),
            const SizedBox(height: 24),
            _buildSoundSelector(),
            const SizedBox(height: 24),
            _buildVolumeAndVibrationSelector(),
            const SizedBox(height: 24),
            _buildSnoozeSelector(),
            if (_selectedAlarmType == '전화알람') ...[
              const SizedBox(height: 24),
              _buildConceptSelector(),
              const SizedBox(height: 24),
              _buildSituationInput(),
              const SizedBox(height: 24),
              _buildVoiceSelector(),
            ],
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmTitleInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알람 제목',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _alarmTitleController,
              decoration: const InputDecoration(
                hintText: '알람 제목을 입력하세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시간 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '요일 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _days.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알람 유형',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('일반알람'),
                    value: '일반알람',
                    groupValue: _selectedAlarmType,
                    onChanged: (value) {
                      setState(() {
                        _selectedAlarmType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('전화알람'),
                    value: '전화알람',
                    groupValue: _selectedAlarmType,
                    onChanged: (value) {
                      setState(() {
                        _selectedAlarmType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '미션 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMission,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _missions.map((mission) {
                return DropdownMenuItem(
                  value: mission,
                  child: Text(mission),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMission = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeAndVibrationSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '소리 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('소리크기: ${(_volume * 100).round()}%'),
                      Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _volume = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    const Text('진동'),
                    Switch(
                      value: _isVibrationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isVibrationEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '스누즈 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('스누즈 간격'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _snoozeMinutes,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _snoozeMinutesOptions.map((minutes) {
                          return DropdownMenuItem(
                            value: minutes,
                            child: Text('${minutes}분'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _snoozeMinutes = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('스누즈 횟수'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _snoozeCount,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _snoozeCountOptions.map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text('${count}회'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _snoozeCount = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알람음 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _openSoundSelection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedSound,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '탭하여 알람음 선택',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _toggleSoundPlayback,
                  icon: Icon(
                    _isSoundPlaying ? Icons.pause : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '추천 컨셉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _concepts.map((concept) {
                final isSelected = _selectedConcept == concept;
                return FilterChip(
                  label: Text(concept),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedConcept = concept;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상황 및 컨셉 입력',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _situationController,
              decoration: const InputDecoration(
                hintText: '전화알람에서 사용할 상황과 컨셉을 입력하세요\n예: 운동 전 격려, 회의 전 준비 등',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '목소리 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedVoice,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _voices.map((voice) {
                      return DropdownMenuItem(
                        value: voice,
                        child: Text(voice),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVoice = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _toggleVoicePlayback,
                  icon: Icon(
                    _isVoicePlaying ? Icons.pause : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveAlarm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          widget.alarmData != null ? '알람 수정' : '알람 저장',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _openSoundSelection() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SoundSelectionScreen(
          currentSound: _selectedSound,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedSound = result;
      });
    }
  }

  void _toggleSoundPlayback() {
    setState(() {
      _isSoundPlaying = !_isSoundPlaying;
      if (_isVoicePlaying) {
        _isVoicePlaying = false; // 다른 재생 중지
      }
    });
    
    if (_isSoundPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedSound} 재생 중...'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '중지',
            onPressed: () {
              setState(() {
                _isSoundPlaying = false;
              });
            },
          ),
        ),
      );
    }
  }

  void _toggleVoicePlayback() {
    setState(() {
      _isVoicePlaying = !_isVoicePlaying;
      if (_isSoundPlaying) {
        _isSoundPlaying = false; // 다른 재생 중지
      }
    });
    
    if (_isVoicePlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedVoice} 미리듣기 중...'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '중지',
            onPressed: () {
              setState(() {
                _isVoicePlaying = false;
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _saveAlarm() async {
    try {
      if (_selectedAlarmType == '전화알람') {
        // GPT 모닝콜 알람 생성
        await _saveGPTMorningCallAlarm();
      } else {
        // 일반 알람 생성
        await _saveLocalAlarm();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.alarmData != null ? '알람이 수정되었습니다!' : '알람이 저장되었습니다!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('알람 저장 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// GPT 모닝콜 알람 저장
  Future<void> _saveGPTMorningCallAlarm() async {
    print('🌅 GPT 모닝콜 알람 저장 시작...');
    print('📝 알람 제목: ${_alarmTitleController.text}');
    print('⏰ 알람 시간: ${_selectedTime.hour}:${_selectedTime.minute}');
    print('📅 선택된 요일: $_selectedDays');
    print('🎯 알람 타입: $_selectedAlarmType');
    
    try {
      // 현재 사용자 정보 가져오기
      final authState = ref.read(authStateProvider);
      final userName = authState.user?.nickname ?? '사용자';
      print('👤 현재 사용자 닉네임: $userName');
      
      final service = MorningCallAlarmService();
      print('🔧 MorningCallAlarmService 인스턴스 생성 완료');
      
      // 사용자 이름 업데이트
      service.updateUserName(userName);
      
      // 서비스가 초기화되지 않은 경우 초기화 시도
      if (!service.isInitialized) {
        print('⚠️ 서비스가 초기화되지 않음. 초기화 시도 중...');
        await service.initialize(
          gptApiKey: '', // API 키 없이도 기본 알람 기능은 동작
          userName: userName,
        );
        print('✅ 서비스 초기화 완료');
      } else {
        print('✅ 서비스가 이미 초기화됨');
      }

      // 선택된 요일들을 숫자 리스트로 변환 (1=월요일, 7=일요일)
      final selectedDayNumbers = <int>[];
      for (int i = 0; i < _selectedDays.length; i++) {
        final dayName = _days[i];
        if (_selectedDays.contains(dayName)) {
          selectedDayNumbers.add(i + 1);
        }
      }
      print('📅 변환된 요일 숫자: $selectedDayNumbers');

      final title = _alarmTitleController.text.isNotEmpty ? _alarmTitleController.text : '모닝콜 알람';
      print('📝 최종 알람 제목: $title');
      
      final scheduledTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      print('⏰ 스케줄된 시간: $scheduledTime');
      
      print('🚀 scheduleMorningCallAlarm 호출 시작...');
      await service.scheduleMorningCallAlarm(
        title: title,
        scheduledTime: scheduledTime,
        repeatDays: selectedDayNumbers.isNotEmpty ? selectedDayNumbers : null,
        description: _situationController.text.isNotEmpty ? _situationController.text : '모닝콜 알람',
      );
      print('✅ scheduleMorningCallAlarm 호출 완료');
      
    } catch (e, stackTrace) {
      print('❌ GPT 모닝콜 알람 저장 중 오류 발생:');
      print('   오류 메시지: $e');
      print('   스택 트레이스: $stackTrace');
      rethrow; // 에러를 다시 던져서 상위에서 처리하도록 함
    }
  }

  /// 일반 로컬 알람 저장
  Future<void> _saveLocalAlarm() async {
    final service = LocalAlarmService.instance;
    
    // 서비스 초기화
    await service.initialize();

    // 선택된 요일들을 숫자 리스트로 변환
    final selectedDayNumbers = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      final dayName = _days[i];
      if (_selectedDays.contains(dayName)) {
        selectedDayNumbers.add(i + 1);
      }
    }

    final title = _alarmTitleController.text.isNotEmpty ? _alarmTitleController.text : '알람';
    
    await service.createAlarm(
      title: title,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      repeatDays: selectedDayNumbers,
      vibrate: _isVibrationEnabled,
      snoozeEnabled: true,
      snoozeInterval: _snoozeMinutes,
      label: title,
      isEnabled: true,
    );
  }

  @override
  void dispose() {
    _alarmTitleController.dispose();
    _situationController.dispose();
    super.dispose();
  }
}