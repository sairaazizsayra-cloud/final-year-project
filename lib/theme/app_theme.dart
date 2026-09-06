import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand colors for Keychain Shop — warm brass / cream boutique retail look.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFB87333); // Brass / copper
  static const Color primaryDark = Color(0xFF8B5A2B);
  static const Color primaryLight = Color(0xFFD4A574);
  static const Color secondary = Color(0xFF2C3E50); // Charcoal blue
  static const Color accent = Color(0xFFE8A87C); // Soft peach accent

  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0EBE3);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  static const Color border = Color(0xFFE0D8CE);
  static const Color divider = Color(0xFFEDE6DC);
  static const Color shimmerBase = Color(0xFFE8E0D6);
  static const Color shimmerHighlight = Color(0xFFF5F0EA);
}

class AppRadii {
  AppRadii._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get soft => const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get brass => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.32),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme();
    final displayText = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseText.copyWith(
        displayLarge: displayText.displayLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: displayText.displayMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: displayText.displaySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: displayText.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: displayText.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: displayText.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.textPrimary),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        bodySmall: baseText.bodySmall?.copyWith(color: AppColors.textHint),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryLight.withValues(alpha: 0.35),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        side: const BorderSide(color: AppColors.border),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primaryDark : AppColors.textHint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primaryDark : AppColors.textHint,
            size: 24,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.divider,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textOnPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }
}
