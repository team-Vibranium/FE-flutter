import 'package:flutter/material.dart';
import 'call_detail_screen.dart';

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  // 더미 데이터
  final List<Map<String, dynamic>> _callHistory = const [
    {
      'date': '2025-09-22',
      'status': '성공',
      'time': '07:15',
      'duration': '2분 30초',
      'summary': '일어날 시간입니다. 사용자가 정상적으로 응답했습니다.',
    },
    {
      'date': '2025-09-21',
      'status': '실패',
      'time': '08:00',
      'duration': '10초',
      'summary': '10초 무발화로 실패 처리되었습니다.',
    },
    {
      'date': '2025-09-20',
      'status': '성공',
      'time': '07:30',
      'duration': '1분 45초',
      'summary': '사용자가 빠르게 응답하여 성공했습니다.',
    },
    {
      'date': '2025-09-19',
      'status': '성공',
      'time': '06:45',
      'duration': '3분 15초',
      'summary': '퍼즐 미션을 완료하며 성공했습니다.',
    },
    {
      'date': '2025-09-18',
      'status': '실패',
      'time': '07:20',
      'duration': '10초',
      'summary': '응답 없이 실패 처리되었습니다.',
    },
    {
      'date': '2025-09-17',
      'status': '성공',
      'time': '07:00',
      'duration': '2분 10초',
      'summary': '정확한 시간에 일어나 성공했습니다.',
    },
    {
      'date': '2025-09-16',
      'status': '성공',
      'time': '08:15',
      'duration': '1분 30초',
      'summary': '스누즈 후 정상적으로 일어났습니다.',
    },
    {
      'date': '2025-09-15',
      'status': '실패',
      'time': '07:45',
      'duration': '10초',
      'summary': '알람을 무시하고 실패했습니다.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통화 기록'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // 최근 통화 요약 카드
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '최근 통화 요약',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryStats(context),
              ],
            ),
          ),
          
          // 통화 기록 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _callHistory.length,
              itemBuilder: (context, index) {
                final call = _callHistory[index];
                return _buildCallHistoryItem(context, call);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context) {
    final successCount = _callHistory.where((call) => call['status'] == '성공').length;
    final failureCount = _callHistory.where((call) => call['status'] == '실패').length;
    final successRate = _callHistory.isNotEmpty 
        ? ((successCount / _callHistory.length) * 100).round()
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            '총 통화',
            '${_callHistory.length}회',
            Icons.phone,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            '성공률',
            '$successRate%',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            '실패',
            '$failureCount회',
            Icons.cancel,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCallHistoryItem(BuildContext context, Map<String, dynamic> call) {
    final isSuccess = call['status'] == '성공';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          child: Icon(
            isSuccess ? Icons.check : Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              call['date'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                call['status'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${call['time']} • ${call['duration']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              call['summary'],
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallDetailScreen(
                callData: call,
              ),
            ),
          );
        },
      ),
    );
  }
}
