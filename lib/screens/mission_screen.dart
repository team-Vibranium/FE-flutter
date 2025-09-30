import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/puzzle_provider.dart';
import '../core/models/puzzle_mission.dart';

class MissionScreen extends ConsumerStatefulWidget {
  final String alarmTitle;
  final VoidCallback onMissionCompleted;
  final VoidCallback? onMissionFailed;

  const MissionScreen({
    super.key,
    required this.alarmTitle,
    required this.onMissionCompleted,
    this.onMissionFailed,
  });

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    // 미션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(puzzleStateProvider.notifier).startNewPuzzle();
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(puzzleStateProvider);
    final puzzleNotifier = ref.read(puzzleStateProvider.notifier);

    // 미션 완료 시 처리
    if (puzzleState.isCompleted && puzzleState.isCorrect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog();
      });
    }

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('🧩 미션 해결'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
      ),
      body: puzzleState.currentMission == null
          ? const Center(child: CircularProgressIndicator())
          : _buildMissionContent(puzzleState, puzzleNotifier),
    );
  }

  Widget _buildMissionContent(PuzzleState puzzleState, PuzzleNotifier puzzleNotifier) {
    final mission = puzzleState.currentMission!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 헤더
            _buildHeader(),
            const SizedBox(height: 30),

            // 미션 타입 표시
            _buildMissionTypeCard(mission.type),
            const SizedBox(height: 30),

            // 질문
            _buildQuestionCard(mission.question),
            const SizedBox(height: 40),

            // 선택지들 (스크롤 가능하게 변경)
            Expanded(
              child: SingleChildScrollView(
                child: _buildOptionsGrid(mission.options, puzzleState, puzzleNotifier),
              ),
            ),

            // 하단 버튼들
            _buildBottomButtons(puzzleState, puzzleNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.indigo,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.alarmTitle} 알람',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '미션을 해결하면 알람이 해제됩니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTypeCard(PuzzleType type) {
    String typeText;
    IconData typeIcon;
    Color typeColor;

    switch (type) {
      case PuzzleType.numberSequence:
        typeText = '숫자 순서';
        typeIcon = Icons.format_list_numbered;
        typeColor = Colors.blue;
        break;
      case PuzzleType.patternMatch:
        typeText = '패턴 매칭';
        typeIcon = Icons.pattern;
        typeColor = Colors.green;
        break;
      case PuzzleType.colorSequence:
        typeText = '색상 순서';
        typeIcon = Icons.palette;
        typeColor = Colors.orange;
        break;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: typeColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon, color: typeColor, size: 20),
            const SizedBox(width: 8),
            Text(
              typeText,
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOptionsGrid(
    List<String> options, 
    PuzzleState puzzleState, 
    PuzzleNotifier puzzleNotifier
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5, // 높이를 줄여서 공간 절약
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = puzzleState.selectedAnswer == option;
        final isCompleted = puzzleState.isCompleted;

        Color cardColor;
        Color textColor;
        IconData? iconData;

        if (isCompleted) {
          if (option == puzzleState.currentMission!.correctAnswer) {
            // 정답
            cardColor = Colors.green;
            textColor = Colors.white;
            iconData = Icons.check_circle;
          } else if (isSelected) {
            // 선택했지만 틀린 답
            cardColor = Colors.red;
            textColor = Colors.white;
            iconData = Icons.cancel;
          } else {
            // 선택하지 않은 오답
            cardColor = Colors.grey.shade300;
            textColor = Colors.grey.shade600;
          }
        } else {
          // 아직 완료되지 않음
          if (isSelected) {
            cardColor = Colors.indigo;
            textColor = Colors.white;
          } else {
            cardColor = Colors.white;
            textColor = Colors.black87;
          }
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: isCompleted 
                ? null 
                : () => puzzleNotifier.selectAnswer(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected && !isCompleted 
                      ? Colors.indigo 
                      : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: [
                  if (!isCompleted || option == puzzleState.currentMission!.correctAnswer)
                    BoxShadow(
                      color: cardColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconData != null) ...[
                    Icon(
                      iconData,
                      color: textColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    option,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons(PuzzleState puzzleState, PuzzleNotifier puzzleNotifier) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // 제출 버튼
          if (!puzzleState.isCompleted) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: puzzleState.canSubmit 
                    ? () => puzzleNotifier.submitAnswer()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  puzzleState.selectedAnswer == null 
                      ? '답을 선택해주세요' 
                      : '답 제출하기',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          // 오답 시 다시 시도 버튼 (정답을 선택한 후에만 표시)
          if (puzzleState.isCompleted && !puzzleState.isCorrect) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => puzzleNotifier.startNewPuzzle(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('다른 문제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onMissionFailed,
                    icon: const Icon(Icons.close),
                    label: const Text('포기하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // 간단한 안내 텍스트로 변경 (공간 절약)
          if (!puzzleState.isCompleted && puzzleState.selectedAnswer == null) ...[
            const SizedBox(height: 12),
            Text(
              '답을 선택한 후 제출해주세요',
              style: TextStyle(
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text(
              '미션 성공!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 축하합니다!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 8),
            Text(
              '미션을 성공적으로 해결했습니다.\n알람이 해제됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onMissionCompleted();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }
}
