import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/morning_call_alarm_service.dart';

/// 모닝콜 알람 추가/수정 화면
class MorningCallAddScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingAlarm;

  const MorningCallAddScreen({
    super.key,
    this.existingAlarm,
  });

  @override
  ConsumerState<MorningCallAddScreen> createState() => _MorningCallAddScreenState();
}

class _MorningCallAddScreenState extends ConsumerState<MorningCallAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<bool> _selectedDays = List.filled(7, false);
  bool _isEnabled = true;
  bool _isLoading = false;
  
  final List<String> _weekDays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _loadExistingAlarm();
  }

  void _loadExistingAlarm() {
    if (widget.existingAlarm != null) {
      final alarm = widget.existingAlarm!;
      _titleController.text = alarm['title'] ?? '';
      
      // 시간 파싱
      if (alarm['time'] != null) {
        final timeParts = alarm['time'].toString().split(':');
        if (timeParts.length >= 2) {
          _selectedTime = TimeOfDay(
            hour: int.tryParse(timeParts[0]) ?? 7,
            minute: int.tryParse(timeParts[1]) ?? 0,
          );
        }
      }
      
      // 요일 파싱
      if (alarm['days'] != null && alarm['days'] is List) {
        final days = List<int>.from(alarm['days']);
        for (int i = 0; i < _selectedDays.length; i++) {
          _selectedDays[i] = days.contains(i + 1);
        }
      }
      
      _isEnabled = alarm['isEnabled'] ?? true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.indigo,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleDay(int index) {
    setState(() {
      _selectedDays[index] = !_selectedDays[index];
    });
  }

  Future<void> _saveAlarm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = MorningCallAlarmService();
      
      // 서비스가 초기화되지 않은 경우 초기화 시도
      if (!service.isInitialized) {
        try {
          await service.initialize(
            gptApiKey: '', // API 키 없이도 기본 알람 기능은 동작
            userName: '사용자',
          );
        } catch (e) {
          print('모닝콜 서비스 초기화 오류: $e');
          // API 키가 없어도 기본 알람 기능은 사용할 수 있도록 처리
        }
      }
      
      // 선택된 요일들을 숫자 리스트로 변환 (1=월요일, 7=일요일)
      final selectedDayNumbers = <int>[];
      for (int i = 0; i < _selectedDays.length; i++) {
        if (_selectedDays[i]) {
          selectedDayNumbers.add(i + 1);
        }
      }
      
      // 매일이 선택되지 않은 경우 최소 하나의 요일은 선택되어야 함
      if (selectedDayNumbers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최소 하나의 요일을 선택해주세요')),
        );
        return;
      }

      final alarmData = {
        'id': widget.existingAlarm?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'title': _titleController.text.trim(),
        'days': selectedDayNumbers,
        'isEnabled': _isEnabled,
        'createdAt': widget.existingAlarm?['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (widget.existingAlarm != null) {
        // 기존 알람 삭제 후 새로 생성
        final existingId = int.tryParse(widget.existingAlarm!['id'].toString());
        if (existingId != null) {
          await service.deleteAlarm(existingId);
        }
      }
      
      // 새 알람 생성
      await service.scheduleMorningCallAlarm(
        title: _titleController.text.trim(),
        scheduledTime: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        repeatDays: selectedDayNumbers,
        description: '모닝콜 알람',
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingAlarm != null ? '모닝콜이 수정되었습니다' : '모닝콜이 추가되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.existingAlarm != null ? '모닝콜 수정' : '모닝콜 추가',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 시간 선택
            _buildSectionCard(
              title: '시간',
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.indigo),
                title: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('알람이 울릴 시간을 선택하세요'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectTime,
              ),
            ),

            const SizedBox(height: 16),

            // 제목 입력
            _buildSectionCard(
              title: '제목',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '예: 데이터베이스 수업, 운동하기',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 요일 선택
            _buildSectionCard(
              title: '반복 요일',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final isSelected = _selectedDays[index];
                    return FilterChip(
                      label: Text(_weekDays[index]),
                      selected: isSelected,
                      onSelected: (_) => _toggleDay(index),
                      selectedColor: Colors.indigo.withOpacity(0.2),
                      checkmarkColor: Colors.indigo,
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 활성화 스위치
            _buildSectionCard(
              title: '설정',
              child: SwitchListTile(
                title: const Text('알람 활성화'),
                subtitle: const Text('이 모닝콜을 활성화합니다'),
                value: _isEnabled,
                activeColor: Colors.indigo,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 32),

            // 저장 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAlarm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.existingAlarm != null ? '수정하기' : '저장하기',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}