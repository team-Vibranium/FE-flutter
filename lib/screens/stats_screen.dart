import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // 필터 상태
  String _selectedFilter = 'all'; // all, plus, minus
  String _selectedPeriod = '30days'; // 7days, 30days, 90days

  // 더미 데이터 - 30일 성과 중심
  final int _totalConsumptionPoints = 850; // 소비 포인트
  final int _totalGradePoints = 1250; // 등급 포인트
  final int _last30DaysPoints = 280; // 최근 30일 포인트
  final int _totalAlarms = 45;
  final int _successAlarms = 38;
  final int _missedAlarms = 7;
  final String _averageWakeTime = '07:15';
  final int _consecutiveDays = 12;
  final int _last30DaysSuccessRate = 87; // 최근 30일 성공률
  final int _monthlySuccessRate = 85; // 이번 달 성공률
  final int _monthlyPoints = 320; // 이번 달 포인트

  final List<Map<String, dynamic>> _pointHistory = [
    {'date': '2024-01-15', 'type': '성공', 'points': 10, 'description': '알람 성공 (등급 포인트)', 'category': 'grade'},
    {'date': '2024-01-14', 'type': '성공', 'points': 15, 'description': '퍼즐 보너스 (등급 포인트)', 'category': 'grade'},
    {'date': '2024-01-13', 'type': '소비', 'points': -50, 'description': '아바타 구매 (소비 포인트)', 'category': 'consumption'},
    {'date': '2024-01-12', 'type': '성공', 'points': 10, 'description': '알람 성공 (등급 포인트)', 'category': 'grade'},
    {'date': '2024-01-11', 'type': '성공', 'points': 20, 'description': '연속 성공 보너스 (등급 포인트)', 'category': 'grade'},
    {'date': '2024-01-10', 'type': '소비', 'points': -100, 'description': '캐릭터 구매 (소비 포인트)', 'category': 'consumption'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('통계'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: '포인트'),
            Tab(text: '통계'),
            Tab(text: '캘린더'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPointsTab(),
          _buildStatsTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  Widget _buildPointsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPointsSummary(),
          const SizedBox(height: 16),
          _buildPointsFilter(),
          const SizedBox(height: 16),
          _buildPointsHistory(),
        ],
      ),
    );
  }

  Widget _buildPointsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 포인트 타입별 구분
            Row(
              children: [
                Expanded(
                  child: _buildPointTypeCard('소비 포인트', _totalConsumptionPoints.toString(), 
                      Colors.orange, Icons.shopping_cart, '캐릭터 구매용'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPointTypeCard('등급 포인트', _totalGradePoints.toString(), 
                      Colors.purple, Icons.emoji_events, '티어 시스템용'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 최근 30일 성과
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.purple[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '최근 30일 성과',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('획득 포인트', '+$_last30DaysPoints', Colors.green),
                      _buildMiniStat('성공률', '$_last30DaysSuccessRate%', Colors.blue),
                      _buildMiniStat('연속일', '${_consecutiveDays}일', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointTypeCard(String title, String points, Color color, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            points,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
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
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '필터링',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFilterChip('전체', 'all', _selectedFilter == 'all'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('플러스', 'plus', _selectedFilter == 'plus'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('마이너스', 'minus', _selectedFilter == 'minus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPointsHistory() {
    // 필터링된 히스토리
    List<Map<String, dynamic>> filteredHistory = _pointHistory.where((item) {
      switch (_selectedFilter) {
        case 'plus':
          return item['points'] > 0;
        case 'minus':
          return item['points'] < 0;
        default:
          return true;
      }
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '포인트 내역',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${filteredHistory.length}개',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filteredHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '해당 조건의 내역이 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...filteredHistory.map((item) => _buildPointHistoryItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildPointHistoryItem(Map<String, dynamic> item) {
    final isPositive = item['points'] > 0;
    final isConsumption = item['category'] == 'consumption';
    final color = isPositive ? Colors.green : Colors.red;
    final bgColor = isConsumption ? Colors.orange[50] : Colors.blue[50];
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConsumption ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // 포인트 타입 아이콘
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isConsumption ? Colors.orange[100] : Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConsumption ? Icons.shopping_cart : Icons.emoji_events,
              color: isConsumption ? Colors.orange[700] : Colors.blue[700],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['description'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isConsumption ? Colors.orange[200] : Colors.blue[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isConsumption ? '소비' : '등급',
                        style: TextStyle(
                          fontSize: 10,
                          color: isConsumption ? Colors.orange[800] : Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${item['points'] > 0 ? '+' : ''}${item['points']}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAlarmStats(),
          const SizedBox(height: 16),
          _buildMonthlyPerformance(),
        ],
      ),
    );
  }

  Widget _buildAlarmStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알람 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('총 알람', _totalAlarms.toString(), Icons.alarm),
                ),
                Expanded(
                  child: _buildStatItem('성공', _successAlarms.toString(), Icons.check_circle, Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('놓친 알람', _missedAlarms.toString(), Icons.cancel, Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '평균 기상 시간',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _averageWakeTime,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이번 달 성과',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildPerformanceItem('성공률', '${_monthlySuccessRate}%', Colors.green),
            const SizedBox(height: 12),
            _buildPerformanceItem('연속 성공', '${_consecutiveDays}일', Colors.blue),
            const SizedBox(height: 12),
            _buildPerformanceItem('이번 달 포인트', '$_monthlyPoints', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 월 선택 헤더
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      // 이전 달 로직
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '2024년 1월',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // 다음 달 로직
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 캘린더 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '알람 성공률 캘린더',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCalendarLegend(),
                  const SizedBox(height: 16),
                  _buildCalendarGrid(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 선택된 날짜 상세 정보
          _buildSelectedDateInfo(),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('성공', Colors.green),
        _buildLegendItem('실패', Colors.red),
        _buildLegendItem('알람없음', Colors.grey),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    // 요일 헤더
    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    
    return Column(
      children: [
        // 요일 헤더
        Row(
          children: weekDays.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // 캘린더 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 31, // 1월 31일
          itemBuilder: (context, index) {
            final day = index + 1;
            // 더미 데이터로 성공률 기반 상태 생성
            final successRate = (day * 3) % 100;
            
            Color color;
            String status;
            if (successRate >= 80) {
              color = Colors.green;
              status = 'success';
            } else if (successRate >= 50) {
              color = Colors.orange;
              status = 'partial';
            } else if (successRate > 0) {
              color = Colors.red;
              status = 'failure';
            } else {
              color = Colors.grey;
              status = 'none';
            }

            return GestureDetector(
              onTap: () {
                _showDateDetail(day, status, successRate);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedDateInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '날짜를 탭하면 상세 정보를 확인할 수 있습니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '이번 달 요약',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMonthSummaryItem('총 알람', '62개', Icons.alarm),
                _buildMonthSummaryItem('성공', '54개', Icons.check_circle, Colors.green),
                _buildMonthSummaryItem('실패', '8개', Icons.cancel, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSummaryItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showDateDetail(int day, String status, int successRate) {
    // 더미 데이터
    final totalAlarms = (day % 5) + 1;
    final successAlarms = (successRate * totalAlarms / 100).round();
    final failureAlarms = totalAlarms - successAlarms;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('1월 ${day}일 상세'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('총 알람', '$totalAlarms개'),
            _buildDetailRow('성공', '$successAlarms개', Colors.green),
            _buildDetailRow('실패', '$failureAlarms개', Colors.red),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: successRate / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                successRate >= 80 ? Colors.green : 
                successRate >= 50 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '성공률: $successRate%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}