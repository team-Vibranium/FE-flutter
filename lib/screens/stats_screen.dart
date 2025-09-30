import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
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
  // String _selectedPeriod = '30days'; // 7days, 30days, 90days (미사용)

  // 캘린더 상태
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // API 데이터 상태
  bool _isLoading = true;
  String? _error;
  
  // API에서 가져온 데이터 (임시로 Map 사용)
  Map<String, dynamic>? _pointSummary;
  // Map<String, dynamic>? _statisticsOverview; // 통계 탭 제거로 미사용
  List<Map<String, dynamic>> _pointTransaction = [];
  Map<String, dynamic>? _monthlyStats;
  // (주간 통계 상태 제거)
  Map<String, int>? _todayPoints; // { earned: +, spent: - }
  Map<String, dynamic>? _last30Stats; // 최근 30일 성과

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          apiService.statistics.getMonthlyStatistics(_focusedDay),
          apiService.statistics.getWeeklyStatistics(DateTime.now()),
          apiService.statistics.getRecentDaysStatistics(30),
          apiService.points.getPointTransaction(limit: 10),
          // 오늘 날짜 범위 포인트 내역 (오늘 요약 계산용)
          apiService.points.getPointTransaction(
            startDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
            endDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
          ),
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
            
            // 통계 개요는 캘린더 통합으로 UI에서 미사용
            
            // 월간 통계
            if (results[2].success && results[2].data != null) {
              final monthlyData = results[2].data as PeriodStatistics;
              print('월간 통계 - successRate: ${monthlyData.successRate}, totalAlarms: ${monthlyData.totalAlarms}');
              _monthlyStats = {
                'successRate': monthlyData.totalAlarms > 0 ? monthlyData.successRate.round() : 0,
                'consecutiveDays': null, // API에서 제공되지 않음
                'totalPointsEarned': monthlyData.totalPoints,
              };
            } else {
              _monthlyStats = null; // 데이터 없음
            }
            
            // 주간 통계(미사용) 제거

            // 최근 30일 통계
            if (results[4].success && results[4].data != null) {
              final last30Data = results[4].data as PeriodStatistics;
              print('최근 30일 통계 - successRate: ${last30Data.successRate}, totalAlarms: ${last30Data.totalAlarms}');
              _last30Stats = {
                'totalPointsEarned': last30Data.totalPoints,
                'successRate': last30Data.totalAlarms > 0 ? last30Data.successRate.round() : 0,
              };
            } else {
              _last30Stats = {'totalPointsEarned': 0, 'successRate': 0};
            }
            
            // 포인트 내역
            if (results[5].success && results[5].data != null) {
              final historyData = results[5].data as List<PointTransaction>;
              _pointTransaction = historyData.map<Map<String, dynamic>>((tx) => {
                'amount': tx.amount,
                'type': tx.type,
                'description': tx.description,
                'createdAt': tx.createdAt.toIso8601String(),
              }).toList();
            } else {
              _pointTransaction = [];
            }

            // 오늘 요약 (획득/사용 합계)
            if (results[6].success && results[6].data != null) {
              final todayHistory = results[6].data as List<PointTransaction>;
              int earned = 0;
              int spent = 0;
              for (final tx in todayHistory) {
                final amount = tx.amount;
                if (amount > 0) {
                  earned += amount;
                } else if (amount < 0) {
                  spent += amount.abs();
                }
              }
              _todayPoints = {'earned': earned, 'spent': spent};
            } else {
              _todayPoints = {'earned': 0, 'spent': 0};
            }
            
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            // 오류 발생 시 데이터 없음으로 설정
            _pointSummary = null;
            _monthlyStats = null;
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

  Future<void> _loadMonthlyFor(DateTime date) async {
    try {
      final apiService = ApiService();
      final resp = await apiService.statistics.getMonthlyStatistics(date);
      if (!mounted) return;
      setState(() {
        if (resp.success && resp.data != null) {
          final monthlyData = resp.data as PeriodStatistics;
          _monthlyStats = {
            'successRate': monthlyData.totalAlarms > 0 ? monthlyData.successRate.round() : 0,
            'consecutiveDays': null,
            'totalPointsEarned': monthlyData.totalPoints,
            'totalAlarms': monthlyData.totalAlarms,
            'successAlarms': monthlyData.successAlarms,
            'failedAlarms': monthlyData.failedAlarms,
          };
        }
      });
    } catch (_) {}
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
    // final pointSummary = _pointSummary; // 미사용
    // final weeklyStats = _weeklyStats; // 미사용
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 오늘 요약 (획득/사용)
            if (_todayPoints != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStat('오늘 획득', '+${_todayPoints!['earned']}', Colors.green),
                  _buildMiniStat('오늘 사용', '-${_todayPoints!['spent']}', Colors.red),
                ],
              ),
              const SizedBox(height: 16),
            ],
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
            // 최근 30일 성과 (카드 상단에 표시)
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
                      _buildMiniStat('획득 포인트', '+${_safeGetValue(_last30Stats, 'totalPointsEarned')}', Colors.green),
                      _buildMiniStat('성공률', '${_safeGetValue(_last30Stats, 'successRate')}%', Colors.blue),
                      _buildMiniStat('연속일', '-', Colors.orange),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final isConsumption = (item['type'].toString().toUpperCase()) == 'CONSUMPTION';
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

  // (_buildStatsTab) 통합으로 제거

  // (_buildAlarmStats) 캘린더 통합으로 제거

  // (_buildStatItem) 통합으로 미사용

  // (_buildMonthlyPerformance) 캘린더 통합으로 제거

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
      future: _loadCalendarDataFor(_focusedDay),
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
          final now = _focusedDay;
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
    // 월간 통계 데이터 가져오기 (요약과 성과로 확장)
    // 날짜별 데이터 빠른 조회 맵
    final Map<int, CalendarDay> dayMap = {
      for (final d in calendarData.days) d.day: d,
    };
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
                      final prevMonth = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                      setState(() {
                        _focusedDay = prevMonth;
                      });
                      _loadMonthlyFor(prevMonth);
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
                      final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                      setState(() {
                        _focusedDay = nextMonth;
                      });
                      _loadMonthlyFor(nextMonth);
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 캘린더 + 요약/성과 통합 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '캘린더',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 월 선택 드롭다운 + 좌우 이동
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          final prevMonth = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                          setState(() {
                            _focusedDay = prevMonth;
                          });
                          _loadMonthlyFor(prevMonth);
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      DropdownButton<int>(
                        value: _focusedDay.month,
                        underline: const SizedBox.shrink(),
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(value: m, child: Text('${_focusedDay.year}년 $m월')))
                            .toList(),
                        onChanged: (m) {
                          if (m == null) return;
                          final newMonth = DateTime(_focusedDay.year, m, 1);
                          setState(() {
                            _focusedDay = newMonth;
                          });
                          _loadMonthlyFor(newMonth);
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                          setState(() {
                            _focusedDay = nextMonth;
                          });
                          _loadMonthlyFor(nextMonth);
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCalendarLegend(),
                  const SizedBox(height: 16),
                  TableCalendar(
                    firstDay: DateTime(calendarData.year, calendarData.month, 1).subtract(const Duration(days: 365)),
                    lastDay: DateTime(calendarData.year, calendarData.month, 1).add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    currentDay: DateTime.now(),
                    headerVisible: false,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      final calDay = dayMap[selectedDay.day] ?? CalendarDay(day: selectedDay.day, alarmCount: 0, successCount: 0, failCount: 0, status: 'none');
                      _showDayDetailBottomSheet(calDay);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadMonthlyFor(focusedDay);
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        final d = dayMap[day.day];
                        if (d == null) return const SizedBox.shrink();
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        if (d.alarmCount == 0) {
                          return Positioned(
                            bottom: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey, width: 2),
                              ),
                            ),
                          );
                        }
                        final rate = d.successCount / d.alarmCount;
                        final color = _successGradient(rate, isDark: isDark);
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 2.5),
                            ),
                          ),
                        );
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: TextStyle(color: Colors.red[400]),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                      weekendStyle: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: 12),
                  // 선택한 달 요약 (인라인)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMonthSummaryItem('총 알람', '${_monthlyStats?['totalAlarms'] ?? 0}개', Icons.alarm),
                      _buildMonthSummaryItem('성공', '${_monthlyStats?['successAlarms'] ?? 0}개', Icons.check_circle, Colors.green),
                      _buildMonthSummaryItem('실패', '${_monthlyStats?['failedAlarms'] ?? 0}개', Icons.cancel, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 선택한 달 성과 (인라인)
                  _buildPerformanceItem('성공률', '${_monthlyStats?['successRate'] ?? 0}%', Colors.green),
                  const SizedBox(height: 8),
                  _buildPerformanceItem('포인트', '${_monthlyStats?['totalPointsEarned'] ?? 0}', Colors.orange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 기존 분리 카드 제거됨(통합 카드로 상단에서 표시)
        ],
      ),
    );
  }

  // (통합 카드로 사용되던 보조 위젯 제거)

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

  Future<CalendarStatistics?> _loadCalendarDataFor(DateTime date) async {
    try {
      final apiService = ApiService();
      final response = await apiService.statistics.getCalendarStatistics(
        year: date.year,
        month: date.month,
      );
      
      if (response.success && response.data != null) {
        return response.data as CalendarStatistics;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // (_buildCalendarGrid) TableCalendar로 대체되어 제거

  // (_buildSelectedDateInfo) 통합으로 제거

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

  // (_showDateDetail) 상세 모달은 추후 필요 시 복구

  // (_buildDetailRow) 상세 모달 제거로 미사용

  // (_buildNoDataWidget) 미사용으로 제거

  /// 안전한 데이터 접근 헬퍼
  String _safeGetValue(Map<String, dynamic>? data, String key, [String defaultValue = '-']) {
    if (data == null) return defaultValue;
    final value = data[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  // (_classifyDay) 그라데이션 마커로 대체되어 제거

  void _showDayDetailBottomSheet(CalendarDay day) {
    final success = day.successCount;
    final fail = day.failCount;
    final total = day.alarmCount;
    final percent = total > 0 ? success / total : 0.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('선택한 날짜 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_focusedDay.year}.${_focusedDay.month}.${day.day}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
              const SizedBox(height: 16),
              SuccessDonut(
                percent: percent,
                total: total,
                success: success,
                fail: fail,
                ringColor: _successGradient(percent, isDark: Theme.of(context).brightness == Brightness.dark),
              ),
              const SizedBox(height: 12),
              FutureBuilder<int>(
                future: _getEarnedPointsOnDate(DateTime(_focusedDay.year, _focusedDay.month, day.day)),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  }
                  final pts = snap.data ?? 0;
                  return Text('포인트 +$pts', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary));
                },
          ),
        ],
      ),
        );
      },
    );
  }

}

// (_DayCategory) 사용하지 않아 제거

class SuccessDonut extends StatefulWidget {
  final double percent; // 0.0 ~ 1.0
  final int total;
  final int success;
  final int fail;
  final Color ringColor;
  const SuccessDonut({super.key, required this.percent, required this.total, required this.success, required this.fail, required this.ringColor});

  @override
  State<SuccessDonut> createState() => _SuccessDonutState();
}

class _SuccessDonutState extends State<SuccessDonut> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SuccessDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 160.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: widget.ringColor,
              percent: (widget.percent.clamp(0.0, 1.0)) * _animation.value,
              strokeWidth: 16,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendDot(Theme.of(context).colorScheme.primary, '총 ${widget.total}'),
              const SizedBox(height: 6),
              _legendDot(Colors.green, '성공 ${widget.success}'),
              const SizedBox(height: 6),
              _legendDot(Colors.red, '실패 ${widget.fail}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
        children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Color backgroundColor;
  final Color foregroundColor;
  final double percent;
  final double strokeWidth;
  _DonutPainter({required this.backgroundColor, required this.foregroundColor, required this.percent, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 배경 원
    canvas.drawCircle(center, radius, bgPaint);
    // 진행 원호 (위쪽에서 시작하도록 -90도 회전)
    final startAngle = -90 * 3.1415926535 / 180;
    final sweepAngle = 2 * 3.1415926535 * percent;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// 성공률에 따른 그라데이션 색상 (빨강→주황→초록)
Color _successGradient(double rate, {bool isDark = false}) {
  final clamped = rate.clamp(0.0, 1.0);
  final red = isDark ? Colors.red[300]! : Colors.red;
  final orange = isDark ? Colors.orange[300]! : Colors.orange;
  final green = isDark ? Colors.green[300]! : Colors.green;
  if (clamped < 0.5) {
    final t = clamped / 0.5;
    return Color.lerp(red, orange, t)!;
  } else {
    final t = (clamped - 0.5) / 0.5;
    return Color.lerp(orange, green, t)!;
  }
}

// 하루 획득 포인트 합계 조회
Future<int> _getEarnedPointsOnDate(DateTime date) async {
  try {
    final api = ApiService();
    final resp = await api.points.getPointTransaction(
      startDate: DateTime(date.year, date.month, date.day),
      endDate: DateTime(date.year, date.month, date.day),
    );
    if (!resp.success || resp.data == null) return 0;
    final list = resp.data as List<PointTransaction>;
    int sum = 0;
    for (final tx in list) {
      if (tx.amount > 0) sum += tx.amount;
    }
    return sum;
  } catch (_) {
    return 0;
  }
}
