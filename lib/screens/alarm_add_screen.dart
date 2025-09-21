import 'package:flutter/material.dart';
import 'sound_selection_screen.dart';

class AlarmAddScreen extends StatefulWidget {
  final Map<String, dynamic>? alarmData;
  final Function(Map<String, dynamic>)? onAlarmSaved;
  
  const AlarmAddScreen({super.key, this.alarmData, this.onAlarmSaved});

  @override
  State<AlarmAddScreen> createState() => _AlarmAddScreenState();
}

class _AlarmAddScreenState extends State<AlarmAddScreen> {
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
      final timeParts = alarm['time'].split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      _selectedAlarmType = alarm['type'];
      _selectedDays.clear();
      _selectedDays.addAll(List<String>.from(alarm['days']));
      
      // 기존 데이터가 있으면 로드
      if (alarm['title'] != null) {
        _alarmTitleController.text = alarm['title'];
      }
      if (alarm['tag'] != null) {
        _alarmTitleController.text = alarm['tag']; // 태그를 제목으로 사용
      }
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

  void _saveAlarm() {
    // 알람 데이터 생성
    final alarmData = {
      'id': widget.alarmData?['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      'days': List<String>.from(_selectedDays),
      'type': _selectedAlarmType,
      'isEnabled': widget.alarmData?['isEnabled'] ?? true,
      'tag': _alarmTitleController.text.isNotEmpty ? _alarmTitleController.text : '새 알람',
      'successRate': widget.alarmData?['successRate'] ?? 0,
      'mission': _selectedMission,
      'sound': _selectedSound,
      'voice': _selectedVoice,
      'concept': _selectedConcept,
      'volume': _volume,
      'isVibrationEnabled': _isVibrationEnabled,
      'snoozeMinutes': _snoozeMinutes,
      'snoozeCount': _snoozeCount,
      'situation': _situationController.text,
    };

    // 콜백으로 알람 데이터 전달
    widget.onAlarmSaved?.call(alarmData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.alarmData != null ? '알람이 수정되었습니다!' : '알람이 저장되었습니다!'),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _alarmTitleController.dispose();
    _situationController.dispose();
    super.dispose();
  }
}
