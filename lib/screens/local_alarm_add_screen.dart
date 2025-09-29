import 'package:flutter/material.dart';
import '../core/models/local_alarm.dart';
import '../core/services/local_alarm_service.dart';

/// 로컬 알람 추가/편집 화면
class LocalAlarmAddScreen extends StatefulWidget {
  final LocalAlarm? alarm; // null이면 새 알람, 있으면 편집

  const LocalAlarmAddScreen({super.key, this.alarm});

  @override
  State<LocalAlarmAddScreen> createState() => _LocalAlarmAddScreenState();
}

class _LocalAlarmAddScreenState extends State<LocalAlarmAddScreen> {
  final LocalAlarmService _alarmService = LocalAlarmService.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  late int _selectedHour;
  late int _selectedMinute;
  late Set<int> _selectedDays;
  late bool _vibrate;
  late bool _snoozeEnabled;
  late int _snoozeInterval;
  late bool _isEnabled;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.alarm != null) {
      // 편집 모드
      final alarm = widget.alarm!;
      _titleController.text = alarm.title;
      _labelController.text = alarm.label ?? '';
      _selectedHour = alarm.hour;
      _selectedMinute = alarm.minute;
      _selectedDays = Set<int>.from(alarm.repeatDays);
      _vibrate = alarm.vibrate;
      _snoozeEnabled = alarm.snoozeEnabled;
      _snoozeInterval = alarm.snoozeInterval;
      _isEnabled = alarm.isEnabled;
    } else {
      // 새 알람 모드
      final now = DateTime.now();
      _titleController.text = '알람';
      _selectedHour = now.hour;
      _selectedMinute = now.minute;
      _selectedDays = <int>{};
      _vibrate = true;
      _snoozeEnabled = true;
      _snoozeInterval = 5;
      _isEnabled = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _saveAlarm() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알람 제목을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool result;

      if (widget.alarm != null) {
        // 편집 모드
        final updatedAlarm = widget.alarm!.copyWith(
          title: _titleController.text.trim(),
          hour: _selectedHour,
          minute: _selectedMinute,
          repeatDays: _selectedDays.toList()..sort(),
          vibrate: _vibrate,
          snoozeEnabled: _snoozeEnabled,
          snoozeInterval: _snoozeInterval,
          isEnabled: _isEnabled,
          label: _labelController.text.trim().isEmpty 
              ? null 
              : _labelController.text.trim(),
          updatedAt: DateTime.now(),
        );
        
        result = await _alarmService.updateAlarm(updatedAlarm);
      } else {
        // 새 알람 모드
        final newAlarm = await _alarmService.createAlarm(
          title: _titleController.text.trim(),
          hour: _selectedHour,
          minute: _selectedMinute,
          repeatDays: _selectedDays.toList()..sort(),
          vibrate: _vibrate,
          snoozeEnabled: _snoozeEnabled,
          snoozeInterval: _snoozeInterval,
          isEnabled: _isEnabled,
          label: _labelController.text.trim().isEmpty 
              ? null 
              : _labelController.text.trim(),
        );
        
        result = newAlarm != null;
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (result) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알람 저장에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.alarm != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '알람 편집' : '새 알람'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveAlarm,
              child: const Text('저장'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시간 선택
            _buildTimeSection(),
            const SizedBox(height: 24),

            // 제목 입력
            _buildTitleSection(),
            const SizedBox(height: 24),

            // 반복 요일 선택
            _buildRepeatSection(),
            const SizedBox(height: 24),

            // 라벨 입력
            _buildLabelSection(),
            const SizedBox(height: 24),

            // 옵션 설정
            _buildOptionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시간',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showTimePicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '제목',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '알람 제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatSection() {
    const dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '반복',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isSelected = _selectedDays.contains(index);
                return GestureDetector(
                  onTap: () => _toggleDay(index),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        dayNames[index],
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDays.isEmpty 
                  ? '한번만 울림'
                  : '${dayNames.where((day) => _selectedDays.contains(dayNames.indexOf(day))).join(', ')} 반복',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '라벨 (선택사항)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                hintText: '알람 라벨을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '옵션',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 활성화 스위치
            SwitchListTile(
              title: const Text('알람 활성화'),
              subtitle: const Text('알람을 즉시 활성화합니다'),
              value: _isEnabled,
              onChanged: (value) {
                setState(() => _isEnabled = value);
              },
            ),

            // 진동 스위치
            SwitchListTile(
              title: const Text('진동'),
              subtitle: const Text('알람 시 진동을 사용합니다'),
              value: _vibrate,
              onChanged: (value) {
                setState(() => _vibrate = value);
              },
            ),

            // 스누즈 스위치
            SwitchListTile(
              title: const Text('스누즈'),
              subtitle: Text('${_snoozeInterval}분 간격으로 다시 알립니다'),
              value: _snoozeEnabled,
              onChanged: (value) {
                setState(() => _snoozeEnabled = value);
              },
            ),

            // 스누즈 간격 설정
            if (_snoozeEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('스누즈 간격'),
                subtitle: Text('${_snoozeInterval}분'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showSnoozeIntervalDialog,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSnoozeIntervalDialog() async {
    final intervals = [1, 3, 5, 10, 15, 30];
    
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('스누즈 간격 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) => RadioListTile<int>(
            title: Text('${interval}분'),
            value: interval,
            groupValue: _snoozeInterval,
            onChanged: (value) => Navigator.of(context).pop(value),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() => _snoozeInterval = selected);
    }
  }
}
