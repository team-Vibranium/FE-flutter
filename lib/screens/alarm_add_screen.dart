import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sound_selection_screen.dart';
import '../core/services/local_alarm_service.dart';
import '../core/services/base_api_service.dart';
import 'package:dio/dio.dart';

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
  String _selectedMission = 'NONE';
  String _selectedSound = '기본 알람음';
  String _selectedVoice = 'ALLOY';
  String _selectedConcept = '친근한';
  double _volume = 0.8;
  bool _isVibrationEnabled = true;
  int _snoozeMinutes = 5;
  int _snoozeCount = 3;
  bool _isSoundPlaying = false;
  bool _isVoicePlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final List<String> _selectedDays = [];
  final TextEditingController _alarmTitleController = TextEditingController();
  final TextEditingController _situationController = TextEditingController();

  final List<String> _days = ['월', '화', '수', '목', '금', '토', '일'];
  final Map<String, String> _missions = {
    'NONE': '미션 없음 (알람만 울림)',
    'PUZZLE': 'PUZZLE (퍼즐)',
    'MATH': 'MATH (수학 문제)',
    'MEMORY': 'MEMORY (기억 게임)',
    'QUIZ': 'QUIZ (퀴즈)',
  };
  final Map<String, String> _voices = {
    'ALLOY': 'ALLOY (균형 잡힌 중성적 목소리)',
    'ASH': 'ASH (부드럽고 차분한 목소리)',
    'BALLAD': 'BALLAD (서정적이고 따뜻한 목소리)',
    'CORAL': 'CORAL (활기찬 여성 목소리)',
    'ECHO': 'ECHO (맑고 선명한 목소리)',
    'SAGE': 'SAGE (차분하고 부드러운 목소리)',
    'SHIMMER': 'SHIMMER (밝고 경쾌한 목소리)',
    'VERSE': 'VERSE (리드미컬하고 표현력 있는 목소리)',
  };
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
            if (_selectedAlarmType != '전화알람') _buildSnoozeSelector(),
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
            // 한 줄에 모든 요일 배치
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _days.map((day) {
                final isSelected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        day.substring(0, 1), // 첫 글자만 표시 (월, 화, 수...)
                        style: TextStyle(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDays.isEmpty 
                  ? '요일을 선택하지 않으면 1회용 알람이 됩니다'
                  : '선택된 요일: ${_selectedDays.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
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
              initialValue: _selectedMission,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _missions.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
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
                        initialValue: _snoozeMinutes,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _snoozeMinutesOptions.map((minutes) {
                          return DropdownMenuItem(
                            value: minutes,
                            child: Text('$minutes분'),
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
                        initialValue: _snoozeCount,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _snoozeCountOptions.map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text('$count회'),
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
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedVoice,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      isDense: true,
                    ),
                    items: _voices.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVoice = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    onPressed: _toggleVoicePlayback,
                    icon: Icon(
                      _isVoicePlaying ? Icons.pause : Icons.play_arrow,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      padding: EdgeInsets.zero,
                    ),
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
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const Text(
                      '시간 선택',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('완료'),
                    ),
                  ],
                ),
              ),
              // 시간 선택기
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      _selectedTime = TimeOfDay(
                        hour: newDateTime.hour,
                        minute: newDateTime.minute,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _toggleSoundPlayback() async {
    if (_isSoundPlaying) {
      // 재생 중이면 중지
      await _audioPlayer.stop();
      setState(() {
        _isSoundPlaying = false;
      });
    } else {
      // 다른 재생 중지
      if (_isVoicePlaying) {
        setState(() {
          _isVoicePlaying = false;
        });
      }
      
      try {
        // 선택된 사운드 파일 찾기
        String? soundFile;
        for (String genre in ['차분한 소리', '전통적인 알람', '리듬감 있는 소리', '긴급알람', '이상한 소리']) {
          // 간단한 매핑 (실제로는 더 정확한 매핑 필요)
          if (_selectedSound.contains('기본')) {
            soundFile = 'sounds/전통적인 알람/무난한 소리.mp3';
            break;
          }
        }
        
        if (soundFile == null) {
          // 기본 사운드 사용
          soundFile = 'sounds/전통적인 알람/무난한 소리.mp3';
        }
        
        await _audioPlayer.play(AssetSource(soundFile));
        
        setState(() {
          _isSoundPlaying = true;
        });
        
        // 재생 완료 시 상태 업데이트
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isSoundPlaying = false;
            });
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedSound 재생 중...'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '중지',
              onPressed: () async {
                await _audioPlayer.stop();
                if (mounted) {
                  setState(() {
                    _isSoundPlaying = false;
                  });
                }
              },
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사운드 재생 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleVoicePlayback() async {
    if (_isVoicePlaying) {
      // 재생 중이면 중지
      await _audioPlayer.stop();
      setState(() {
        _isVoicePlaying = false;
      });
    } else {
      // 다른 재생 중지
      if (_isSoundPlaying) {
        setState(() {
          _isSoundPlaying = false;
        });
      }
      
      try {
        // 음성 파일 재생
        final voiceFileName = _selectedVoice.toLowerCase();
        print('Voice 파일 재생 시도: assets/voices/$voiceFileName.wav');
        await _audioPlayer.play(AssetSource('assets/voices/$voiceFileName.wav'));
        
        setState(() {
          _isVoicePlaying = true;
        });
        
        // 재생 완료 시 상태 업데이트
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isVoicePlaying = false;
            });
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_voices[_selectedVoice]} 미리듣기 중...'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '중지',
              onPressed: () async {
                await _audioPlayer.stop();
                if (mounted) {
                  setState(() {
                    _isVoicePlaying = false;
                  });
                }
              },
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('음성 재생 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAlarm() async {
    try {
      int? backendAlarmId = widget.alarmData?['backendAlarmId'] as int?;
      final bool isEditing = widget.alarmData != null;

      // 전화 알람인 경우 백엔드에 저장/수정
      if (_selectedAlarmType == '전화알람') {
        if (isEditing && (backendAlarmId != null)) {
          backendAlarmId = await _updatePhoneAlarmToBackend(backendAlarmId);
        } else {
          backendAlarmId = await _savePhoneAlarmToBackend();
        }
      }

      // 로컬 알람 저장/수정
      await _saveLocalAlarm(backendAlarmId: backendAlarmId);

      // onAlarmSaved 콜백
      if (widget.onAlarmSaved != null) {
        final alarmData = {
          'id': widget.alarmData?['id'],
          'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          'days': _selectedDays,
          'type': _selectedAlarmType,
          'mission': _selectedMission,
          'isEnabled': true,
          'tag': _alarmTitleController.text.isNotEmpty ? _alarmTitleController.text : '알람',
          'title': _alarmTitleController.text.isNotEmpty ? _alarmTitleController.text : '알람',
          'backendAlarmId': backendAlarmId,
        };
        widget.onAlarmSaved!(alarmData);
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


  /// 전화 알람을 백엔드에 저장
  Future<int> _savePhoneAlarmToBackend() async {
    try {
      // Dio 인스턴스 생성
      final dio = Dio();
      dio.options.baseUrl = 'https://prod.proproject.my';
      
      // 인증 토큰 가져오기
      final baseApi = BaseApiService();
      final token = baseApi.accessToken;
      
      dio.options.headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      // 알람 시간 계산 (다음 알람 시간)
      final now = DateTime.now();
      final alarmTime = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);

      // 이미 지났으면 내일로 설정
      final targetTimeLocal = alarmTime.isBefore(now) ? alarmTime.add(const Duration(days: 1)) : alarmTime;

      // UTC로 변환
      final targetTime = targetTimeLocal.toUtc();
      
      // 지시사항 생성
      final instructions = _buildInstructions();
      
      print('📞 전화 알람 백엔드 등록 시작...');
      print('  - 시간: ${targetTime.toIso8601String()}');
      print('  - 지시사항: $instructions');
      print('  - 음성: $_selectedVoice');
      print('  - 토큰: ${token != null ? "있음" : "없음"}');
      
      // 미션이 "NONE"이 아닐 때만 미션 정보 포함
      final Map<String, dynamic> requestData = {
        'alarmTime': targetTime.toIso8601String(),
        'instructions': instructions,
        'voice': _selectedVoice,
      };
      
      // 미션이 "NONE"이 아닐 때만 미션 정보 추가
      if (_selectedMission != 'NONE') {
        requestData['mission'] = _selectedMission;
      }
      
      final response = await dio.post('/api/alarms', data: requestData);

      print('📄 응답 상태 코드: ${response.statusCode}');
      print('📄 응답 본문: ${response.data}');

      if (response.statusCode == 201) {
        print('📄 전체 응답 데이터: ${response.data}');
        print('📄 응답 데이터 타입: ${response.data.runtimeType}');
        
        final responseData = response.data as Map<String, dynamic>;
        print('📄 responseData: $responseData');
        print('📄 responseData 키들: ${responseData.keys.toList()}');
        
        // 응답 구조 확인
        if (responseData.containsKey('data')) {
          final alarmData = responseData['data'] as Map<String, dynamic>;
          print('📄 alarmData: $alarmData');
          print('📄 alarmData 키들: ${alarmData.keys.toList()}');
          
          // ID 필드 확인 - 백엔드는 alarmId 필드로 ID를 제공
          int? alarmId;
          
          // 1. data.alarmId 체크 (백엔드 응답 구조에 맞춤)
          if (alarmData.containsKey('alarmId')) {
            final idValue = alarmData['alarmId'];
            print('📄 alarmId 필드 값: $idValue (타입: ${idValue.runtimeType})');
            
            if (idValue is int) {
              alarmId = idValue;
            } else if (idValue is String) {
              alarmId = int.tryParse(idValue);
            } else if (idValue is num) {
              alarmId = idValue.toInt();
            }
          }
          
          // 2. data.id 체크 (fallback)
          if (alarmId == null && alarmData.containsKey('id')) {
            final idValue = alarmData['id'];
            print('📄 id 필드 값: $idValue (타입: ${idValue.runtimeType})');
            
            if (idValue is int) {
              alarmId = idValue;
            } else if (idValue is String) {
              alarmId = int.tryParse(idValue);
            } else if (idValue is num) {
              alarmId = idValue.toInt();
            }
          }
          
          if (alarmId != null) {
            print('✅ 전화 알람 백엔드 등록 완료: ID $alarmId');
            return alarmId;
          } else {
            print('❌ 알람 ID를 찾을 수 없습니다. 사용 가능한 필드: ${alarmData.keys}');
            print('❌ 각 필드의 값들:');
            alarmData.forEach((key, value) {
              print('  - $key: $value (${value.runtimeType})');
            });
            
            // ID가 없으면 임시 ID 생성 (로컬 알람 ID 사용)
            final tempId = DateTime.now().millisecondsSinceEpoch % 1000000;
            print('⚠️ 임시 ID 생성: $tempId');
            return tempId;
          }
        } else {
          print('❌ 응답에 data 필드가 없습니다. 사용 가능한 필드: ${responseData.keys}');
          print('❌ 전체 응답 구조:');
          responseData.forEach((key, value) {
            print('  - $key: $value (${value.runtimeType})');
          });
          throw Exception('응답에 data 필드가 없습니다');
        }
      } else if (response.statusCode == 409) {
        // 409 Conflict: 이미 같은 시간에 알람이 존재
        print('⚠️ 같은 시간에 알람이 이미 존재합니다. 기존 알람을 조회합니다.');
        return await _findExistingAlarm(dio, targetTime);
      } else {
        print('❌ 전화 알람 등록 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.data}');
        throw Exception('전화 알람 등록 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 전화 알람 백엔드 등록 오류: $e');
      if (e is DioException && e.response != null) {
        print('❌ 에러 상태 코드: ${e.response?.statusCode}');
        print('❌ 에러 응답 본문: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// 전화 알람을 백엔드에서 수정
  Future<int> _updatePhoneAlarmToBackend(int alarmId) async {
    try {
      final dio = Dio();
      dio.options.baseUrl = 'https://prod.proproject.my';

      final baseApi = BaseApiService();
      final token = baseApi.accessToken;
      dio.options.headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // 새 시간 계산 (다음 울릴 시간)
      final now = DateTime.now();
      final alarmTime = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
      final targetTimeLocal = alarmTime.isBefore(now) ? alarmTime.add(const Duration(days: 1)) : alarmTime;
      final targetTime = targetTimeLocal.toUtc();

      final instructions = _buildInstructions();

      // 미션이 "NONE"이 아닐 때만 미션 정보 포함
      final Map<String, dynamic> requestData = {
        'alarmTime': targetTime.toIso8601String(),
        'instructions': instructions,
        'voice': _selectedVoice,
      };
      
      // 미션이 "NONE"이 아닐 때만 미션 정보 추가
      if (_selectedMission != 'NONE') {
        requestData['mission'] = _selectedMission;
      }
      
      final response = await dio.put('/api/alarms/$alarmId', data: requestData);

      if (response.statusCode == 200) {
        return alarmId;
      }
      throw Exception('전화 알람 수정 실패: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// 기존 알람 찾기 (409 Conflict 시)
  Future<int> _findExistingAlarm(Dio dio, DateTime targetTime) async {
    try {
      print('🔍 기존 알람 조회 중...');
      
      // 사용자의 모든 알람 조회
      final response = await dio.get('/api/alarms');
      
      if (response.statusCode == 200) {
        final alarms = response.data['data'] as List<dynamic>;
        
        // 같은 시간의 알람 찾기
        for (final alarm in alarms) {
          final alarmData = alarm as Map<String, dynamic>;
          final alarmTimeStr = alarmData['alarmTime'] as String?;
          
          if (alarmTimeStr != null) {
            final alarmTime = DateTime.parse(alarmTimeStr);
            // 시간만 비교 (분 단위까지)
            if (alarmTime.hour == targetTime.hour && alarmTime.minute == targetTime.minute) {
              final alarmId = alarmData['id'] as int?;
              if (alarmId != null) {
                print('✅ 기존 알람 발견: ID $alarmId');
                return alarmId;
              }
            }
          }
        }
        
        print('❌ 같은 시간의 알람을 찾을 수 없습니다');
        throw Exception('같은 시간의 알람을 찾을 수 없습니다');
      } else {
        print('❌ 알람 목록 조회 실패: ${response.statusCode}');
        throw Exception('알람 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 기존 알람 조회 오류: $e');
      rethrow;
    }
  }

  /// 지시사항 생성
  String _buildInstructions() {
    final title = _alarmTitleController.text.isNotEmpty ? _alarmTitleController.text : '알람';
    final situation = _situationController.text.isNotEmpty ? _situationController.text : '일상적인 상황';

    return '''
$_selectedConcept한 톤으로 $title을 깨워주세요. 상황: $situation.

중요한 규칙:
1. 먼저 친근하게 인사하고 일어날 시간임을 알려주세요.
2. 사용자의 컨디션을 묻고 기상을 격려해주세요 (예: "잘 주무셨나요?", "오늘 기분은 어떠세요?", "일어날 준비 되셨나요?").
3. 사용자가 대답하면, 공감하며 응원의 말을 해주세요.
4. 그 다음 "그럼 정신을 깨우기 위해 간단한 퀴즈 하나 드릴게요!"라고 말하고 퀴즈를 1개 내주세요 (예: "3 더하기 5는?", "오늘은 무슨 요일인가요?").
5. 사용자가 퀴즈에 대답하면 (정답이든 오답이든) "잘하셨어요! 이제 화면의 퀴즈를 풀어서 완전히 깨어나세요!"라고 말하세요.
6. 사용자가 15초 동안 대답하지 않으면 자동으로 다음 단계로 넘어갑니다.
''';
  }

  /// 일반 로컬 알람 저장
  Future<void> _saveLocalAlarm({int? backendAlarmId}) async {
    final service = LocalAlarmService.instance;
    await service.initialize();

    // 요일 숫자 변환 (1=월, 7=일)
    final selectedDayNumbers = <int>[];
    for (int i = 0; i < _days.length; i++) {
      final dayName = _days[i];
      if (_selectedDays.contains(dayName)) {
        selectedDayNumbers.add(i + 1);
      }
    }

    final title = _alarmTitleController.text.isNotEmpty ? _alarmTitleController.text : '알람';
    final bool isEditing = widget.alarmData != null;
    final int? localId = widget.alarmData?['id'] as int?;

    if (isEditing && localId != null) {
      // 기존 알람 업데이트
      final existing = await service.getAlarmById(localId);
      if (existing != null) {
        final updated = existing.copyWith(
          title: title,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          repeatDays: selectedDayNumbers,
          vibrate: _isVibrationEnabled,
          snoozeEnabled: _selectedAlarmType != '전화알람',
          snoozeInterval: _selectedAlarmType != '전화알람' ? _snoozeMinutes : existing.snoozeInterval,
          updatedAt: DateTime.now(),
          type: _selectedAlarmType,
          backendAlarmId: backendAlarmId ?? existing.backendAlarmId,
        );
        await service.updateAlarm(updated);
        return;
      }
    }

    // 신규 생성
    await service.createAlarm(
      title: title,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      repeatDays: selectedDayNumbers,
      vibrate: _isVibrationEnabled,
      snoozeEnabled: _selectedAlarmType != '전화알람',
      snoozeInterval: _selectedAlarmType != '전화알람' ? _snoozeMinutes : 5,
      label: title,
      isEnabled: true,
      type: _selectedAlarmType,
      backendAlarmId: backendAlarmId,
    );
  }

  @override
  void dispose() {
    _alarmTitleController.dispose();
    _situationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}