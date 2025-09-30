import 'package:flutter/material.dart';
import '../core/services/call_management_api_service.dart';
import '../core/models/api_models.dart';

class CallDetailScreen extends StatefulWidget {
  final Map<String, dynamic> callData;

  const CallDetailScreen({super.key, required this.callData});

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  bool _loading = true;
  String? _error;
  List<Utterance> _conversation = [];

  @override
  void initState() {
    super.initState();
    _loadTranscript();
  }

  Future<void> _loadTranscript() async {
    setState(() {
      _loading = true;
      _error = null;
      _conversation = [];
    });
    try {
      final callId = widget.callData['id'] as int?;
      if (callId == null) {
        setState(() {
          _loading = false;
          _error = '잘못된 통화 ID입니다.';
        });
        return;
      }
      final api = CallManagementApiService();
      final res = await api.getCall(callId);
      if (res.success && res.data != null) {
        setState(() {
          _conversation = res.data!.conversation ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = res.message ?? '통화 내용을 불러오지 못했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통화 내용'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          _buildCallHeader(context),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _conversation.isEmpty
                        ? const Center(child: Text('통화 내용이 없습니다.'))
                        : _buildChatLog(),
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    final callStart = widget.callData['callStart'] as DateTime?;
    final callEnd = widget.callData['callEnd'] as DateTime?;

    // Debug: callStart: $callStart
    // Debug: callEnd: $callEnd

    if (callStart == null || callEnd == null) {
      return '알 수 없음';
    }

    final duration = callEnd.difference(callStart);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    // Debug: duration: ${duration.inSeconds}초 ($minutes분 $seconds초)

    if (minutes > 0) {
      return '$minutes분 $seconds초';
    } else {
      return '$seconds초';
    }
  }

  Widget _buildCallHeader(BuildContext context) {
    final callData = widget.callData;
    final isSuccess = callData['status'] == '성공';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                color: isSuccess ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                callData['date'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  callData['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${callData['time']} • ${_calculateDuration()}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatLog() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversation.length,
      itemBuilder: (context, index) {
        final u = _conversation[index];
        return _buildChatBubble(context, u);
      },
    );
  }

  Widget _buildChatBubble(BuildContext context, Utterance u) {
    final isUser = u.speaker == 'user';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Text(
                'AI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(u.timestamp.toIso8601String()),
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Text(
                '나',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    } catch (_) {
      return iso;
    }
  }
}
