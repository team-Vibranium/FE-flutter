import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'call_detail_screen.dart';
import '../core/widgets/cards/app_card.dart';
import '../core/widgets/chips/status_chip.dart';
import '../core/design_system/app_spacing.dart';
import '../core/design_system/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/models/api_models.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all'; // all, success, failure
  List<CallLog> _displayedHistory = [];
  final List<CallLog> _allCallHistory = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _hasMoreData = true;


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
        _displayedHistory.clear();
        _allCallHistory.clear();
        _hasMoreData = true;
      });
      
      await _loadMoreData();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final apiService = ApiService();
      final response = await apiService.callLog.getCallLogsByPage(
        limit: _itemsPerPage,
        offset: _allCallHistory.length,
      );

      if (response.success && response.data != null) {
        // API 응답을 CallLog 리스트로 변환
        final responseData = response.data as Map<String, dynamic>;
        final callLogsList = responseData['callLogs'] as List<dynamic>? ?? [];
        final newCallLogs = callLogsList
            .map((item) {
              if (item is CallLog) return item;
              if (item is Map<String, dynamic>) return CallLog.fromJson(item);
              return null;
            })
            .whereType<CallLog>()
            .toList();
        
        if (mounted) {
          setState(() {
            _allCallHistory.addAll(newCallLogs);
            _updateDisplayedHistory();
            _currentPage++;
            _hasMoreData = newCallLogs.length == _itemsPerPage;
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = response.message ?? '통화 내역을 불러오는데 실패했습니다';
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _updateDisplayedHistory() {
    List<CallLog> filteredData;
    switch (_selectedFilter) {
      case 'success':
        filteredData = _allCallHistory.where((call) => call.isSuccessful).toList();
        break;
      case 'failure':
        filteredData = _allCallHistory.where((call) => !call.isSuccessful).toList();
        break;
      default:
        filteredData = _allCallHistory;
    }
    _displayedHistory = filteredData;
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _updateDisplayedHistory();
  }

  String _getSummary(CallLog call) {
    if (call.conversationList != null && call.conversationList!.isNotEmpty) {
      // 첫 번째 AI 발화를 요약으로 사용
      final firstAssistant = call.conversationList!
          .where((u) => u.speaker == 'assistant')
          .firstOrNull;
      if (firstAssistant != null) {
        return firstAssistant.text.length > 50
            ? '${firstAssistant.text.substring(0, 50)}...'
            : firstAssistant.text;
      }
    }
    return call.isSuccessful ? '알람 성공' : '알람 실패';
  }

  String _calculateDuration(CallLog call) {
    if (call.callEnd == null) {
      return '진행중';
    }

    final duration = call.callEnd!.difference(call.callStart);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '$minutes분 $seconds초';
    } else {
      return '$seconds초';
    }
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
              '통화 내역을 불러오는 중 오류가 발생했습니다',
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
              onPressed: _loadInitialData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통화 기록'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _error != null
          ? _buildErrorWidget()
          : _isLoading && _displayedHistory.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
              itemCount: _displayedHistory.length + (_isLoadingMore ? 1 : 0),
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        final successCount = _allCallHistory.where((call) => call.isSuccessful).length;
        final failureCount = _allCallHistory.where((call) => !call.isSuccessful).length;
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

  Widget _buildCallHistoryItem(BuildContext context, CallLog call) {
    final isSuccess = call.isSuccessful;
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
                callData: {
                  'id': call.id,
                  'date': call.startTime.toString().substring(0, 10),
                  'status': call.isSuccessful ? '성공' : '실패',
                  'time': call.startTime.toString().substring(11, 16),
                  'callStart': call.callStart,
                  'callEnd': call.callEnd,
                },
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
                        call.startTime.toString().substring(0, 10),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusChip(
                        label: call.isSuccessful ? '성공' : '실패',
                        color: statusColor,
                        icon: statusIcon,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${call.startTime.toString().substring(11, 16)} • ${_calculateDuration(call)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _getSummary(call),
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
