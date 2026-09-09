import 'package:flutter/material.dart';

abstract final class AppColors {
  // Neutral paper foundation
  static const ink = Color(0xFF0F2340);
  static const mutedInk = Color(0xFF5F6877);

  static const paper = Color(0xFFFFFDF8);
  static const neutralCard = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E7EC);
  static const softBlue = Color(0xFFDDE7FA);
  static const iconTile = Color(0xFFE8EEF7);
  static const topicIcon = Color(0xFF31507A);
  static const softGreen = Color(0xFFE6F3EA);

  // Logo colours
  static const brandCyan = Color(0xFF29A9DC);
  static const brandPink = Color(0xFFED0A8C);
  static const brandPeriwinkle = Color(0xFF7391CF);

  // Navy primary actions and blue accents
  static const primary = Color(0xFF0F2340);
  static const secondary = Color(0xFF3157B3);

  // Semantic colours
  static const success = Color(0xFF34A66F);
  static const error = Color(0xFFBA1A1A);
}

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.softBlue,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.softBlue,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.success,
      onTertiary: AppColors.ink,
      tertiaryContainer: AppColors.softGreen,
      onTertiaryContainer: AppColors.ink,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.neutralCard,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.mutedInk,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 35,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      displayMedium: TextStyle(
        fontSize: 31,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      headlineLarge: TextStyle(
        fontSize: 25,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 21,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 19,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: AppColors.mutedInk,
      ),
      bodyMedium: TextStyle(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: AppColors.mutedInk,
      ),
      bodySmall: TextStyle(
        fontSize: 10,
        height: 1.4,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: AppColors.mutedInk,
      ),
      labelLarge: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      labelMedium: TextStyle(
        fontSize: 10,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
      labelSmall: TextStyle(
        fontSize: 9,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.mutedInk,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: 'Inter',

      textTheme: textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.ink,
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.neutralCard,
        elevation: 3,
        shadowColor: AppColors.ink.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.ink,
        textColor: AppColors.ink,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: AppColors.ink),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralCard,
        labelStyle: const TextStyle(
          color: AppColors.mutedInk,
          letterSpacing: 0.5,
        ),
        hintStyle: const TextStyle(
          color: AppColors.mutedInk,
          letterSpacing: 0.5,
        ),
        prefixIconColor: AppColors.mutedInk,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.mutedInk,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.success,
        linearTrackColor: AppColors.softGreen,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.neutralCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.neutralCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
