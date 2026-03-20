import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _textThemeColored(
    TextTheme base, {
    required Color primary,
    required Color secondary,
    required Color muted,
  }) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: primary),
      displayMedium: base.displayMedium?.copyWith(color: primary),
      displaySmall: base.displaySmall?.copyWith(color: primary),
      headlineLarge: base.headlineLarge?.copyWith(color: primary),
      headlineMedium: base.headlineMedium?.copyWith(color: primary),
      headlineSmall: base.headlineSmall?.copyWith(color: primary),
      titleLarge: base.titleLarge?.copyWith(color: primary),
      titleMedium: base.titleMedium?.copyWith(color: primary),
      titleSmall: base.titleSmall?.copyWith(color: primary),
      bodyLarge: base.bodyLarge?.copyWith(color: secondary),
      bodyMedium: base.bodyMedium?.copyWith(color: secondary),
      bodySmall: base.bodySmall?.copyWith(color: muted),
      labelLarge: base.labelLarge?.copyWith(color: primary),
      labelMedium: base.labelMedium?.copyWith(color: secondary),
      labelSmall: base.labelSmall?.copyWith(color: muted),
    );
  }

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.dark,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          error: AppColors.primary,
          onError: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: _textThemeColored(
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          primary: AppColors.textPrimary,
          secondary: AppColors.textSecondary,
          muted: AppColors.textMuted,
        ),
        primaryTextTheme: _textThemeColored(
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          primary: AppColors.textPrimary,
          secondary: AppColors.textSecondary,
          muted: AppColors.textMuted,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.dark,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 19),
          actionsIconTheme:
              const IconThemeData(color: AppColors.textPrimary, size: 19),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        dividerColor: AppColors.divider,
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightScaffold,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          error: AppColors.primaryDark,
          onError: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
        ),
        textTheme: _textThemeColored(
          GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          primary: AppColors.lightTextPrimary,
          secondary: AppColors.lightTextSecondary,
          muted: AppColors.lightTextMuted,
        ),
        primaryTextTheme: _textThemeColored(
          GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          primary: AppColors.lightTextPrimary,
          secondary: AppColors.lightTextSecondary,
          muted: AppColors.lightTextMuted,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightScaffold,
          elevation: 0,
          centerTitle: false,
          iconTheme:
              const IconThemeData(color: AppColors.lightTextPrimary, size: 19),
          actionsIconTheme:
              const IconThemeData(color: AppColors.lightTextPrimary, size: 19),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.lightTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightDivider, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightDivider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle:
              GoogleFonts.inter(color: AppColors.lightTextMuted, fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        dividerColor: AppColors.lightDivider,
      );
}
