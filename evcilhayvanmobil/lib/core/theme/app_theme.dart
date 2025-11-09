import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Exposes the light theme used across the application. Placing the theme in
/// a dedicated file keeps `main.dart` clean and ensures other widgets can
/// easily access shared styling bits.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.light,
      primary: AppPalette.primary,
      secondary: AppPalette.secondary,
      tertiary: AppPalette.tertiary,
      surface: AppPalette.surface,
      background: AppPalette.background,
    );

    final textTheme = ThemeData.light().textTheme.apply(
          bodyColor: AppPalette.onBackground,
          displayColor: AppPalette.onBackground,
        );

    return ThemeData(
      colorScheme: baseColorScheme.copyWith(
        surfaceVariant: const Color(0xFFEDEBFF),
        onSurfaceVariant: AppPalette.onSurfaceVariant,
        inversePrimary: AppPalette.secondary,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppPalette.onBackground,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        color: AppPalette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 12,
        shadowColor: AppPalette.primary.withOpacity(0.12),
        margin: const EdgeInsets.all(12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
          shadowColor: AppPalette.primary.withOpacity(0.28),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.secondary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.secondary.withOpacity(0.12),
        selectedColor: AppPalette.secondary,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppPalette.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppPalette.primary.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: AppPalette.primary,
            width: 1.6,
          ),
        ),
        hintStyle: TextStyle(
          color: AppPalette.onSurfaceVariant.withOpacity(0.7),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: AppPalette.primary.withOpacity(0.08),
          foregroundColor: AppPalette.primary,
          shape: const StadiumBorder(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.primary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: AppPalette.primary.withOpacity(0.08),
        thickness: 1,
        space: 32,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}