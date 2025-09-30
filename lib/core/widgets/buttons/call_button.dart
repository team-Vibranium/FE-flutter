import 'package:flutter/material.dart';

/// 통화 화면용 원형 버튼 컴포넌트
/// AngyCall-Flutter-Design-Spec.md 기반
class CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const CallButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 72.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            size: size * 0.4,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
