import 'package:flutter/material.dart';

/// App-wide accent (cyan theme).
abstract final class AppColors {
  static const accent = Colors.cyanAccent;
  static const accentMuted = Color(0xFF80DEEA);
  static const accentSoft = Color(0xFF4DD0E1);

  /// Darker teal for secondary emphasis (protocol ECG, alternate accents).
  static const accentTeal = Color(0xFF00897B);
}
