import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/local_alarm.dart';
import '../core/services/local_alarm_service.dart';
import 'local_alarm_add_screen.dart';

/// 로컬 알람 목록 화면
class LocalAlarmListScreen extends ConsumerStatefulWidget {
  const LocalAlarmListScreen({super.key});

  @override
  ConsumerState<LocalAlarmListScreen> createState() => _LocalAlarmListScreenState();
}

class _LocalAlarmListScreenState extends ConsumerState<LocalAlarmListScreen> {
  final LocalAlarmService _alarmService = LocalAlarmService.instance;
  List<LocalAlarm> _alarms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final alarms = await _alarmService.getAllAlarms();
      
      if (mounted) {
        setState(() {
          _alarms = alarms..sort((a, b) {
            // 시간순 정렬 (시 -> 분)
            if (a.hour != b.hour) return a.hour.compareTo(b.hour);
            return a.minute.compareTo(b.minute);
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAlarm(LocalAlarm alarm) async {
    try {
      final result = await _alarmService.toggleAlarm(alarm.id, !alarm.isEnabled);
      if (result) {
        await _loadAlarms();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              alarm.isEnabled 
                  ? '${alarm.title} 알람이 비활성화되었습니다'
                  : '${alarm.title} 알람이 활성화되었습니다'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('알람 설정 변경 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAlarm(LocalAlarm alarm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알람 삭제'),
        content: Text('${alarm.title} 알람을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _alarmService.deleteAlarm(alarm.id);
        if (result) {
          await _loadAlarms();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${alarm.title} 알람이 삭제되었습니다'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('알람 삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToAddAlarm() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const LocalAlarmAddScreen(),
      ),
    );

    if (result == true) {
      _loadAlarms();
    }
  }

  Future<void> _navigateToEditAlarm(LocalAlarm alarm) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LocalAlarmAddScreen(alarm: alarm),
      ),
    );

    if (result == true) {
      _loadAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlarms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _alarms.isEmpty
                  ? _buildEmptyWidget()
                  : _buildAlarmList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAlarm,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '알람을 불러오는 중 오류가 발생했습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAlarms,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '설정된 알람이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 첫 번째 알람을 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmList() {
    return RefreshIndicator(
      onRefresh: _loadAlarms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return _buildAlarmItem(alarm);
        },
      ),
    );
  }

  Widget _buildAlarmItem(LocalAlarm alarm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alarm.isEnabled ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 시간 표시
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.timeString,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: alarm.isEnabled 
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        alarm.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: alarm.isEnabled 
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 활성화 스위치
                Switch(
                  value: alarm.isEnabled,
                  onChanged: (value) => _toggleAlarm(alarm),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 반복 요일 및 추가 정보
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  alarm.repeatDaysString,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (alarm.label != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.label,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alarm.label!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 알람 옵션 표시
            Row(
              children: [
                if (alarm.vibrate) ...[
                  Icon(
                    Icons.vibration,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                ],
                if (alarm.snoozeEnabled) ...[
                  Icon(
                    Icons.snooze,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${alarm.snoozeInterval}분',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (alarm.soundPath != null) ...[
                  Icon(
                    Icons.music_note,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                ],
                
                const Spacer(),
                
                // 편집 및 삭제 버튼
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _navigateToEditAlarm(alarm),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteAlarm(alarm),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: Colors.red[300],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
