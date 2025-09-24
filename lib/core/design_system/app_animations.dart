import 'package:flutter/material.dart';

/// AngyCall 앱의 애니메이션 시스템
/// AngyCall-Flutter-Design-Spec.md 기반
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

class AppCurves {
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve standard = Curves.easeInOutCubic;
}
