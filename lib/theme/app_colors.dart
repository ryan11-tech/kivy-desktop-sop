import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Brand default primary. Use in `const` contexts and as the reset value.
  static const Color primaryDefault = Color(0xFF8B0000);

  /// Active primary color. Mutable so the saved user preference can recolor the
  /// app's many `AppColors.primary` call sites without a full Theme migration.
  /// Set in [ZinmeApp] from loaded preferences; defaults to [primaryDefault].
  static Color primary = primaryDefault;

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceHigh = Color(0xFF202020);
  static const Color gold = Color(0xFFC9A84C);
  static const Color amber = Color(0xFFE8A020);
  static const Color silver = Color(0xFFA8A8B0);
  static const Color success = Color(0xFF22B55A);
  static const Color info = Color(0xFF2278E8);
  static const Color hot = Color(0xFFE65926);
  static const Color cold = Color(0xFF3399F2);
  static const Color favorite = Color(0xFFF2C733);

  /// Parses a `#RRGGBB` (or `RRGGBB`) hex string into an opaque [Color].
  /// Returns [fallback] (default [primary]) when the string is malformed.
  static Color fromHex(String hex, {Color fallback = primaryDefault}) {
    try {
      final cleaned = hex.replaceAll('#', '').trim();
      if (cleaned.length != 6) return fallback;
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
