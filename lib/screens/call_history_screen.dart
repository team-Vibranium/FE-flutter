import 'package:flutter/material.dart';
import 'call_detail_screen.dart';
import '../core/widgets/cards/app_card.dart';
import '../core/widgets/chips/status_chip.dart';
import '../core/design_system/app_spacing.dart';
import '../core/design_system/app_colors.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all'; // all, success, failure
  List<Map<String, dynamic>> _displayedHistory = [];
  bool _isLoading = false;
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // 더미 데이터 (더 많은 데이터로 확장)
  final List<Map<String, dynamic>> _allCallHistory = const [
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
    {
      'date': '2025-09-14',
      'status': '성공',
      'time': '06:30',
      'duration': '3분 20초',
      'summary': '일찍 일어나서 성공했습니다.',
    },
    {
      'date': '2025-09-13',
      'status': '성공',
      'time': '07:10',
      'duration': '2분 15초',
      'summary': '정상적으로 응답하여 성공했습니다.',
    },
    {
      'date': '2025-09-12',
      'status': '실패',
      'time': '08:30',
      'duration': '5초',
      'summary': '무응답으로 실패했습니다.',
    },
    {
      'date': '2025-09-11',
      'status': '성공',
      'time': '07:25',
      'duration': '1분 50초',
      'summary': '빠른 응답으로 성공했습니다.',
    },
    {
      'date': '2025-09-10',
      'status': '성공',
      'time': '06:45',
      'duration': '4분 10초',
      'summary': '퍼즐 미션 완료 후 성공했습니다.',
    },
    {
      'date': '2025-09-09',
      'status': '실패',
      'time': '07:55',
      'duration': '8초',
      'summary': '짧은 응답으로 실패했습니다.',
    },
    {
      'date': '2025-09-08',
      'status': '성공',
      'time': '07:05',
      'duration': '2분 45초',
      'summary': '정시에 일어나 성공했습니다.',
    },
    {
      'date': '2025-09-07',
      'status': '성공',
      'time': '08:20',
      'duration': '3분 30초',
      'summary': '스누즈 사용 후 성공했습니다.',
    },
    {
      'date': '2025-09-06',
      'status': '실패',
      'time': '07:40',
      'duration': '12초',
      'summary': '부족한 대화로 실패했습니다.',
    },
    {
      'date': '2025-09-05',
      'status': '성공',
      'time': '06:50',
      'duration': '2분 25초',
      'summary': '명확한 응답으로 성공했습니다.',
    },
    {
      'date': '2025-09-04',
      'status': '성공',
      'time': '07:30',
      'duration': '1분 55초',
      'summary': '정상적인 통화로 성공했습니다.',
    },
    {
      'date': '2025-09-03',
      'status': '실패',
      'time': '08:10',
      'duration': '6초',
      'summary': '매우 짧은 응답으로 실패했습니다.',
    },
    {
      'date': '2025-09-02',
      'status': '성공',
      'time': '07:15',
      'duration': '3분 05초',
      'summary': '충분한 대화로 성공했습니다.',
    },
    {
      'date': '2025-09-01',
      'status': '성공',
      'time': '06:55',
      'duration': '2분 40초',
      'summary': '활기찬 응답으로 성공했습니다.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // 시뮬레이션을 위한 딜레이
    Future.delayed(const Duration(milliseconds: 500), () {
      final filteredData = _getFilteredData();
      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredData.length);
      
      if (startIndex < filteredData.length) {
        final newItems = filteredData.sublist(startIndex, endIndex);
        setState(() {
          _displayedHistory.addAll(newItems);
          _currentPage++;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredData() {
    switch (_selectedFilter) {
      case 'success':
        return _allCallHistory.where((call) => call['status'] == '성공').toList();
      case 'failure':
        return _allCallHistory.where((call) => call['status'] == '실패').toList();
      default:
        return _allCallHistory;
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _displayedHistory.clear();
      _currentPage = 0;
    });
    _loadMoreData();
  }

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
            margin: const EdgeInsets.all(AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.primaryContainer,
              elevation: Theme.of(context).brightness == Brightness.dark ? 8.0 : null,
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
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '통화 기록',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSummaryStats(context),
                ],
              ),
            ),
          ),
          
          // 필터링 버튼
          _buildFilterButtons(),
          
          // 통화 기록 리스트 (무한 스크롤)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _displayedHistory.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _displayedHistory.length) {
                  return _buildLoadingIndicator();
                }
                final call = _displayedHistory[index];
                return _buildCallHistoryItem(context, call);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildSegmentedButton('전체', 'all', _selectedFilter == 'all'),
            _buildSegmentedButton('성공', 'success', _selectedFilter == 'success'),
            _buildSegmentedButton('실패', 'failure', _selectedFilter == 'failure'),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButton(String label, String value, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
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
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context) {
    final successCount = _allCallHistory.where((call) => call['status'] == '성공').length;
    final failureCount = _allCallHistory.where((call) => call['status'] == '실패').length;
    final successRate = _allCallHistory.isNotEmpty 
        ? ((successCount / _allCallHistory.length) * 100).round()
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            '총 통화',
            '${_allCallHistory.length}회',
            Icons.phone,
            AppColors.enhancedInfo, // 더 명확한 파란색
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            '성공률',
            '$successRate%',
            Icons.check_circle,
            AppColors.enhancedSuccess, // 더 명확한 녹색
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            '실패',
            '$failureCount회',
            Icons.cancel,
            AppColors.enhancedPrimary, // 더 명확한 빨간색
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCallHistoryItem(BuildContext context, Map<String, dynamic> call) {
    final isSuccess = call['status'] == '성공';
    final statusColor = isSuccess ? AppColors.enhancedSuccess : AppColors.enhancedPrimary;
    final statusIcon = isSuccess ? Icons.check_circle : Icons.cancel;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
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
        child: Row(
          children: [
            // 상태 아이콘
            CircleAvatar(
              backgroundColor: statusColor,
              radius: 20,
              child: Icon(
                statusIcon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            
            // 통화 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        call['date'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusChip(
                        label: call['status'],
                        color: statusColor,
                        icon: statusIcon,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${call['time']} • ${call['duration']}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    call['summary'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // 화살표 아이콘
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
