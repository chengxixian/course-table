import 'package:flutter/material.dart';

class HsuTheme {
  static const seed = Color(0xFF0B57D0);
  static const palettes = <String, String>{
    'system': '跟随系统',
    'blue': '湖蓝',
    'green': '松绿',
    'purple': '鸢尾紫',
    'orange': '琥珀橙',
    'pink': '山茶粉',
    'teal': '青瓷',
  };
  static const paletteSeeds = <String, Color>{
    'blue': Color(0xFF0B57D0),
    'green': Color(0xFF146C43),
    'purple': Color(0xFF6750A4),
    'orange': Color(0xFFB25B00),
    'pink': Color(0xFFB3266A),
    'teal': Color(0xFF006A6A),
  };

  static Color seedFor(String palette) => paletteSeeds[palette] ?? seed;

  static ColorScheme lightScheme([ColorScheme? dynamic, String palette = 'system']) =>
      (palette == 'system' ? dynamic : null) ??
      ColorScheme.fromSeed(seedColor: seedFor(palette), brightness: Brightness.light);

  static ColorScheme darkScheme([ColorScheme? dynamic, String palette = 'system']) =>
      (palette == 'system' ? dynamic : null) ??
      ColorScheme.fromSeed(seedColor: seedFor(palette), brightness: Brightness.dark);

  static ThemeData build(ColorScheme scheme, {String fontStyle = 'fangsoong'}) {
    final pixel = fontStyle == 'pixel';
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: pixel ? 'FusionPixel' : 'FangSongCN',
      fontFamilyFallback: pixel
          ? ['FangSongCN', 'TimesNewRoman', 'Microsoft YaHei UI']
          : ['TimesNewRoman', 'Microsoft YaHei UI', 'Noto Sans SC'],
    );
    final text = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -1.8),
      displayMedium: base.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -1.2),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.8),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.4),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelMedium,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.55), thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}



