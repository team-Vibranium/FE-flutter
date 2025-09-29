import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/models/api_models.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // 필터 상태
  String _selectedFilter = 'all'; // all, plus, minus
  String _selectedPeriod = '30days'; // 7days, 30days, 90days

  // API 데이터 상태
  bool _isLoading = true;
  String? _error;
  
  // API에서 가져온 데이터 (임시로 Map 사용)
  Map<String, dynamic>? _pointSummary;
  Map<String, dynamic>? _statisticsOverview;
  List<Map<String, dynamic>> _pointTransaction = [];
  Map<String, dynamic>? _monthlyStats;
  Map<String, dynamic>? _weeklyStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final apiService = ApiService();
      
      try {
        // 병렬로 실제 API 데이터 로드
        final results = await Future.wait([
          apiService.points.getPointBalance(),
          apiService.statistics.getOverview(), // API 스펙에 맞게 수정
          apiService.statistics.getMonthlyStatistics(DateTime.now()),
          apiService.statistics.getWeeklyStatistics(DateTime.now()),
          apiService.points.getPointTransaction(limit: 10),
        ]);

        if (mounted) {
          setState(() {
            // 포인트 요약
            _pointSummary = results[0].success ? results[0].data as Map<String, dynamic>? : {
              'consumptionPoints': 0,
              'gradePoints': 0,
              'totalPoints': 0,
              'currentGrade': 'BRONZE',
            };
            
            // 통계 개요
            if (results[1].success && results[1].data != null) {
              final overview = results[1].data as StatisticsOverview;
              _statisticsOverview = {
                'totalAlarms': overview.totalAlarms,
                'successAlarms': overview.successAlarms,
                'missedAlarms': overview.missedAlarms,
                'successRate': overview.successRate,
                'consecutiveDays': overview.consecutiveDays,
                'averageWakeTime': overview.averageWakeTime,
                'last30DaysSuccessRate': overview.last30DaysSuccessRate,
                'monthlySuccessRate': overview.monthlySuccessRate,
                'monthlyPoints': overview.monthlyPoints,
              };
            } else {
              _statisticsOverview = {
                'totalAlarms': 0,
                'successAlarms': 0,
                'missedAlarms': 0,
                'successRate': 0.0,
                'consecutiveDays': 0,
                'averageWakeTime': '00:00',
                'last30DaysSuccessRate': 0.0,
                'monthlySuccessRate': 0.0,
                'monthlyPoints': 0,
              };
            }
            
            // 월간 통계
            if (results[2].success && results[2].data != null) {
              final monthlyData = results[2].data as PeriodStatistics;
              _monthlyStats = {
                'successRate': (monthlyData.successRate * 100).round(),
                'consecutiveDays': null, // API에서 제공되지 않음
                'totalPointsEarned': monthlyData.totalPoints,
              };
            } else {
              _monthlyStats = null; // 데이터 없음
            }
            
            // 주간 통계
            if (results[3].success && results[3].data != null) {
              final weeklyData = results[3].data as PeriodStatistics;
              _weeklyStats = {
                'totalPointsEarned': weeklyData.totalPoints,
                'successRate': (weeklyData.successRate * 100).round(),
                'consecutiveDays': null, // API에서 제공되지 않음
              };
            } else {
              _weeklyStats = null; // 데이터 없음
            }
            
            // 포인트 내역
            if (results[4].success && results[4].data != null) {
              final historyData = results[4].data! as List<dynamic>;
              _pointTransaction = historyData.map<Map<String, dynamic>>((item) => {
                'amount': (item as Map<String, dynamic>)['amount'],
                'type': (item as Map<String, dynamic>)['type'],
                'description': (item as Map<String, dynamic>)['description'],
                'createdAt': (item as Map<String, dynamic>)['createdAt'],
              }).toList();
            } else {
              _pointTransaction = [];
            }
            
            _isLoading = false;
          });
        }
      } catch (e) {
        print('통계 데이터 로드 오류: $e');
        if (mounted) {
          setState(() {
            // 오류 발생 시 데이터 없음으로 설정
            _pointSummary = null;
            _statisticsOverview = null;
            _monthlyStats = null;
            _weeklyStats = null;
            _pointTransaction = [];
            _isLoading = false;
          });
        }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPointsTab(),
                    _buildStatsTab(),
                    _buildCalendarTab(),
                  ],
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
              '데이터를 불러오는 중 오류가 발생했습니다',
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
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
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
    final pointSummary = _pointSummary;
    final weeklyStats = _weeklyStats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 포인트 타입별 구분
            Row(
              children: [
                Expanded(
                  child: _buildPointTypeCard(
                    '소비 포인트', 
                    '${_pointSummary?['consumptionPoints'] ?? 0}', 
                    Colors.orange, 
                    Icons.shopping_cart, 
                    '캐릭터 구매용'
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPointTypeCard(
                    '등급 포인트', 
                    '${_pointSummary?['gradePoints'] ?? 0}', 
                    Colors.purple, 
                    Icons.emoji_events, 
                    '티어 시스템용'
                  ),
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
                      _buildMiniStat('획득 포인트', '+${_safeGetValue(_weeklyStats, 'totalPointsEarned')}', Colors.green),
                      _buildMiniStat('성공률', '${_safeGetValue(_weeklyStats, 'successRate')}%', Colors.blue),
                      _buildMiniStat('연속일', '${_safeGetValue(_weeklyStats, 'consecutiveDays')}일', Colors.orange),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentedButton('전체', 'all', _selectedFilter == 'all', isFirst: true),
                  ),
                  Expanded(
                    child: _buildSegmentedButton('플러스', 'plus', _selectedFilter == 'plus'),
                  ),
                  Expanded(
                    child: _buildSegmentedButton('마이너스', 'minus', _selectedFilter == 'minus', isLast: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButton(String label, String value, bool isSelected, {bool isFirst = false, bool isLast = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPointsHistory() {
    // 필터링된 히스토리
    List<Map<String, dynamic>> filteredHistory = _pointTransaction.where((item) {
      switch (_selectedFilter) {
        case 'plus':
          return item['amount'] > 0;
        case 'minus':
          return item['amount'] < 0;
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
              ...filteredHistory.map((item) => _buildPointTransactionItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildPointTransactionItem(Map<String, dynamic> item) {
    final isPositive = item['amount'] > 0;
    final isConsumption = item['type'] == 'consumption';
    final color = isPositive ? Colors.green : Colors.red;
    final bgColor = isConsumption ? Colors.orange[50] : Colors.blue[50];
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConsumption ? Colors.orange.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3),
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
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item['createdAt'].toString().substring(0, 10),
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
            '${item['amount'] > 0 ? '+' : ''}${item['amount']}',
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
                  child: _buildStatItem('총 알람', '${_statisticsOverview?['totalAlarms'] ?? 0}', Icons.alarm),
                ),
                Expanded(
                  child: _buildStatItem('성공', '${_statisticsOverview?['successfulAlarms'] ?? 0}', Icons.check_circle, Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('놓친 알람', '${(_statisticsOverview?['totalAlarms'] ?? 0) - (_statisticsOverview?['successfulAlarms'] ?? 0)}', Icons.cancel, Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.surfaceVariant,
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
                    _statisticsOverview?['averageWakeTime'] ?? '00:00',
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
            _buildPerformanceItem('성공률', '${_monthlyStats?['successRate'] ?? 0}%', Colors.green),
            const SizedBox(height: 12),
            _buildPerformanceItem('연속 성공', '${_monthlyStats?['consecutiveDays'] ?? 0}일', Colors.blue),
            const SizedBox(height: 12),
            _buildPerformanceItem('이번 달 포인트', '${_monthlyStats?['totalPointsEarned'] ?? 0}', Colors.orange),
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
            color: color.withValues(alpha: 0.1),
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
    return FutureBuilder<CalendarStatistics?>(
      future: _loadCalendarData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('캘린더 데이터 로드 실패: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }
        
        final calendarData = snapshot.data;
        if (calendarData == null) {
          // 데이터가 없어도 기본 캘린더 표시
          final now = DateTime.now();
          final emptyCalendarData = CalendarStatistics(
            year: now.year,
            month: now.month,
            days: [], // 빈 데이터
          );
          return _buildCalendarContent(emptyCalendarData);
        }
        
        return _buildCalendarContent(calendarData);
      },
    );
  }

  Widget _buildCalendarContent(CalendarStatistics calendarData) {
    // 월간 통계 데이터 가져오기
    final monthlyStats = _monthlyStats;
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
                    '${calendarData.year}년 ${calendarData.month}월',
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
                  _buildCalendarGrid(calendarData),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 선택된 날짜 상세 정보
          _buildSelectedDateInfo(monthlyStats),
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

  Future<CalendarStatistics?> _loadCalendarData() async {
    try {
      final apiService = ApiService();
      final now = DateTime.now();
      final response = await apiService.statistics.getCalendarStatistics(
        year: now.year,
        month: now.month,
      );
      
      if (response.success && response.data != null) {
        return response.data as CalendarStatistics;
      }
      return null;
    } catch (e) {
      print('캘린더 데이터 로드 오류: $e');
      return null;
    }
  }

  Widget _buildCalendarGrid(CalendarStatistics calendarData) {
    // 요일 헤더
    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    
    // 해당 월의 첫 번째 날과 마지막 날 계산
    final firstDay = DateTime(calendarData.year, calendarData.month, 1);
    final lastDay = DateTime(calendarData.year, calendarData.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7; // 일요일이 0이 되도록 조정
    final daysInMonth = lastDay.day;
    
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
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              // 빈 칸
              return Container();
            }
            
            final day = index - firstWeekday + 1;
            final dayData = calendarData.days.firstWhere(
              (d) => d.day == day,
              orElse: () => CalendarDay(
                day: day,
                alarmCount: 0,
                successCount: 0,
                failCount: 0,
                status: 'none',
              ),
            );
            
            Color color;
            String status = dayData.status;
            if (status == 'success') {
              color = Colors.green;
            } else if (status == 'failure') {
              color = Colors.red;
            } else if (status == 'partial') {
              color = Colors.orange;
            } else {
              color = Colors.grey[300]!;
            }

            return GestureDetector(
              onTap: () {
                _showDateDetail(day, status, dayData.alarmCount, dayData.successCount, dayData.failCount);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: 0.8),
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

  Widget _buildSelectedDateInfo(Map<String, dynamic>? monthlyStats) {
    // 월간 통계 데이터에서 값 추출
    final totalAlarms = monthlyStats?['totalAlarms'] ?? 0;
    final successAlarms = monthlyStats?['successAlarms'] ?? 0;
    final failedAlarms = monthlyStats?['failedAlarms'] ?? 0;
    final successRate = monthlyStats?['successRate'] ?? 0;
    
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
                _buildMonthSummaryItem('총 알람', '${totalAlarms}개', Icons.alarm),
                _buildMonthSummaryItem('성공', '${successAlarms}개', Icons.check_circle, Colors.green),
                _buildMonthSummaryItem('실패', '${failedAlarms}개', Icons.cancel, Colors.red),
              ],
            ),
            if (totalAlarms > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '성공률: ${(successRate * 100).round()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ],
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

  void _showDateDetail(int day, String status, int alarmCount, int successCount, int failCount) {
    final totalAlarms = alarmCount;
    final successAlarms = successCount;
    final failureAlarms = failCount;
    final successRate = totalAlarms > 0 ? (successAlarms / totalAlarms * 100).round() : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${DateTime.now().month}월 ${day}일 상세'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('총 알람', '$totalAlarms개'),
            _buildDetailRow('성공', '$successAlarms개', Colors.green),
            _buildDetailRow('실패', '$failureAlarms개', Colors.red),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: totalAlarms > 0 ? successRate / 100 : 0,
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

  /// 데이터가 없을 때 표시할 위젯
  Widget _buildNoDataWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.data_usage_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '서버에서 데이터를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 안전한 데이터 접근 헬퍼
  String _safeGetValue(Map<String, dynamic>? data, String key, [String defaultValue = '-']) {
    if (data == null) return defaultValue;
    final value = data[key];
    if (value == null) return defaultValue;
    return value.toString();
  }
}