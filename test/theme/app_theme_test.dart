import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/theme/app_colors.dart';
import 'package:zinme_app/theme/app_theme.dart';

void main() {
  group('AppColors.fromHex', () {
    test('parses #RRGGBB into an opaque color', () {
      expect(AppColors.fromHex('#22B55A'), const Color(0xFF22B55A));
    });

    test('parses bare RRGGBB without the hash', () {
      expect(AppColors.fromHex('C9A84C'), const Color(0xFFC9A84C));
    });

    test('falls back to primaryDefault on malformed input', () {
      expect(AppColors.fromHex('nope'), AppColors.primaryDefault);
      expect(AppColors.fromHex('#12'), AppColors.primaryDefault);
      expect(AppColors.fromHex('zzzzzz'), AppColors.primaryDefault);
    });

    test('honors a custom fallback', () {
      expect(AppColors.fromHex('', fallback: AppColors.gold), AppColors.gold);
    });
  });

  group('AppTheme.dark', () {
    test('uses the brand default primary when none is given', () {
      expect(AppTheme.dark().colorScheme.primary, AppColors.primaryDefault);
    });

    test('applies the chosen primary to the color scheme and chips', () {
      const chosen = Color(0xFF2278E8);
      final theme = AppTheme.dark(primary: chosen);
      expect(theme.colorScheme.primary, chosen);
      expect(theme.chipTheme.selectedColor, chosen);
    });
  });
}
