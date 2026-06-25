// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño de YO FREE-LANCER
/// Paleta verde oscura, inspirada en la estética original Android
class AppTheme {
  AppTheme._();

  // ── Brand Colors ─────────────────────────────────────────────────────────
  static const Color brandGreen        = Color(0xFF32B354);
  static const Color brandGreenLight   = Color(0xFF4CAF50);
  static const Color brandGreenDark    = Color(0xFF1E7A33);
  static const Color brandGreenAccent  = Color(0xFFC8E6C9);

  // ── Dark palette ──────────────────────────────────────────────────────────
  static const Color bgDark            = Color(0xFF121513);
  static const Color surfaceDark       = Color(0xFF1E231F);
  static const Color cardDark          = Color(0xFF27302A);
  static const Color cardInnerDark     = Color(0xFF1A2A1E);
  static const Color borderDark        = Color(0xFF2E3A31);
  static const Color textPrimaryDark   = Color(0xFFE9F2EB);
  static const Color textSecondaryDark = Color(0xFF8EA990);
  static const Color textHintDark      = Color(0xFF586B5C);
  static const Color alertRed          = Color(0xFF9A2626);
  static const Color alertRedLight     = Color(0xFFCF6679);
  static const Color warningOrange     = Color(0xFFFF9800);
  static const Color infoBlue          = Color(0xFF2196F3);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const Color bgLight           = Color(0xFFF5F7F5);
  static const Color surfaceLight      = Color(0xFFFFFFFF);
  static const Color cardLight         = Color(0xFFF0F5F1);
  static const Color textPrimaryLight  = Color(0xFF121513);
  static const Color textSecondaryLight= Color(0xFF4A6450);

  // ── Typography ───────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    final base = GoogleFonts.spaceGroteskTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: primary, fontWeight: FontWeight.w700, letterSpacing: -1.0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: primary, fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primary, fontWeight: FontWeight.w600,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: primary, fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primary, fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: primary, fontWeight: FontWeight.w500,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: primary, fontWeight: FontWeight.w500,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: primary, fontWeight: FontWeight.w400,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: secondary, fontWeight: FontWeight.w400,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: secondary, fontSize: 12,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: primary, fontWeight: FontWeight.w600, letterSpacing: 0.5,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: secondary, letterSpacing: 0.8,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: secondary, letterSpacing: 1.0,
      ),
    );
  }

  // ── ColorScheme dark ─────────────────────────────────────────────────────
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: brandGreen,
    onPrimary: Colors.white,
    primaryContainer: cardInnerDark,
    onPrimaryContainer: brandGreenAccent,
    secondary: brandGreenLight,
    onSecondary: Colors.black,
    secondaryContainer: cardDark,
    onSecondaryContainer: textPrimaryDark,
    tertiary: warningOrange,
    onTertiary: Colors.black,
    error: alertRedLight,
    onError: Colors.white,
    surface: surfaceDark,
    onSurface: textPrimaryDark,
    onSurfaceVariant: textSecondaryDark,
    outline: borderDark,
    outlineVariant: textHintDark,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: textPrimaryDark,
    onInverseSurface: bgDark,
    inversePrimary: brandGreenDark,
  );

  // ── ColorScheme light ─────────────────────────────────────────────────────
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: brandGreen,
    onPrimary: Colors.white,
    primaryContainer: brandGreenAccent,
    onPrimaryContainer: brandGreenDark,
    secondary: brandGreenLight,
    onSecondary: Colors.white,
    secondaryContainer: cardLight,
    onSecondaryContainer: textPrimaryLight,
    tertiary: warningOrange,
    onTertiary: Colors.white,
    error: alertRed,
    onError: Colors.white,
    surface: surfaceLight,
    onSurface: textPrimaryLight,
    onSurfaceVariant: textSecondaryLight,
    outline: Color(0xFFCDD8CE),
    outlineVariant: Color(0xFFE0EAE2),
    shadow: Color(0x1A000000),
    scrim: Color(0x80000000),
    inverseSurface: surfaceDark,
    onInverseSurface: textPrimaryDark,
    inversePrimary: brandGreenLight,
  );

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkScheme,
      textTheme: _buildTextTheme(textPrimaryDark, textSecondaryDark),
      scaffoldBackgroundColor: bgDark,

      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimaryDark,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimaryDark),
        actionsIconTheme: const IconThemeData(color: textPrimaryDark),
      ),

      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandGreen,
          side: const BorderSide(color: brandGreen, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandGreen,
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        hintStyle: GoogleFonts.spaceGrotesk(
          color: textHintDark,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRedLight, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
        prefixIconColor: textSecondaryDark,
        suffixIconColor: textSecondaryDark,
        labelStyle: GoogleFonts.spaceGrotesk(color: textSecondaryDark),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgDark,
        selectedItemColor: brandGreen,
        unselectedItemColor: textHintDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: brandGreen.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: brandGreen);
          }
          return const IconThemeData(color: textHintDark);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.spaceGrotesk(fontSize: 10);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: brandGreen, fontWeight: FontWeight.w700,
            );
          }
          return base.copyWith(color: textHintDark);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: brandGreen.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 12, fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: borderDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 0.5,
        space: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimaryDark, fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandGreen,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandGreen;
          return textHintDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brandGreen.withValues(alpha: 0.4);
          }
          return borderDark;
        }),
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightScheme,
      textTheme: _buildTextTheme(textPrimaryLight, textSecondaryLight),
      scaffoldBackgroundColor: bgLight,

      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0EAE2), width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCDD8CE), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
      ),
    );
  }

  // ── Gradientes reutilizables ──────────────────────────────────────────────
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGreen, brandGreenDark],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDark, surfaceDark],
  );

  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cardDark,
      cardInnerDark.withValues(alpha: 0.8),
    ],
  );
}

/// Extensiones de contexto para acceso rápido al tema
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Radios de borde estándar
class AppRadius {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double pill = 100;

  static BorderRadius get xsR   => BorderRadius.circular(xs);
  static BorderRadius get smR   => BorderRadius.circular(sm);
  static BorderRadius get mdR   => BorderRadius.circular(md);
  static BorderRadius get lgR   => BorderRadius.circular(lg);
  static BorderRadius get xlR   => BorderRadius.circular(xl);
  static BorderRadius get xxlR  => BorderRadius.circular(xxl);
  static BorderRadius get pillR => BorderRadius.circular(pill);
}

/// Espaciados estándar
class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}
