import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/morning_call_alarm_service.dart';
// 기본 Material Design 사용
import 'morning_call_add_screen.dart';
import 'morning_call_screen.dart';

/// 모닝콜 알람 목록 화면
class MorningCallAlarmListScreen extends ConsumerStatefulWidget {
  const MorningCallAlarmListScreen({super.key});

  @override
  ConsumerState<MorningCallAlarmListScreen> createState() => _MorningCallAlarmListScreenState();
}

class _MorningCallAlarmListScreenState extends ConsumerState<MorningCallAlarmListScreen> {
  final MorningCallAlarmService _alarmService = MorningCallAlarmService();
  
  List<Map<String, dynamic>> _alarms = [];
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
      
      setState(() {
        _alarms = alarms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAlarm(int alarmId) async {
    try {
      await _alarmService.deleteAlarm(alarmId);
      await _loadAlarms();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알람이 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _testMorningCall(String alarmTitle) async {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MorningCallScreen(
            alarmTitle: alarmTitle,
            userName: _alarmService.userName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('모닝콜 시작 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌅 GPT 모닝콜'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAlarms,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MorningCallAddScreen(),
            ),
          );
          
          if (result == true) {
            _loadAlarms();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('모닝콜 추가'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
              '오류가 발생했습니다',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500).copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12).copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAlarms,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_alarms.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAlarms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return _buildAlarmCard(alarm);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '모닝콜 알람이 없습니다',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500).copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GPT와 함께하는 특별한 모닝콜을\n추가해보세요!',
            style: const TextStyle(fontSize: 14).copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MorningCallAddScreen(),
                ),
              );
              
              if (result == true) {
                _loadAlarms();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('첫 모닝콜 추가하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    final id = alarm['id'] as int;
    final title = alarm['title'] as String;
    final description = alarm['description'] as String?;
    final scheduledTime = DateTime.parse(alarm['scheduledTime'] as String);
    final repeatDays = alarm['repeatDays'] as List<dynamic>?;
    final isActive = alarm['isActive'] as bool? ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12).copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) {
                    // TODO: 알람 활성화/비활성화 구현
                  },
                  activeColor: Colors.indigo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                if (repeatDays != null && repeatDays.isNotEmpty) ...[
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatRepeatDays(repeatDays.cast<int>()),
                    style: const TextStyle(fontSize: 12).copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _testMorningCall(title),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('테스트'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: BorderSide(color: Colors.indigo),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: 알람 수정 화면으로 이동
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('수정'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmDialog(id, title),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('삭제'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  String _formatRepeatDays(List<int> days) {
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    return days.map((day) => dayNames[day - 1]).join(', ');
  }

  void _showDeleteConfirmDialog(int alarmId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알람 삭제'),
        content: Text('\'$title\' 알람을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAlarm(alarmId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
