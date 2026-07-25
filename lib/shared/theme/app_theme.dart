// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño de YO FREE-LANCER
/// Paleta verde, generada desde un seed Material 3 y afinada a la
/// identidad de marca original.
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
  static const Color cardInnerLight    = Color(0xFFE3EFE5);
  static const Color borderLight       = Color(0xFFE0EAE2);
  static const Color textPrimaryLight  = Color(0xFF121513);
  static const Color textSecondaryLight= Color(0xFF4A6450);
  static const Color textHintLight     = Color(0xFF93A899);

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
      displaySmall: base.displaySmall?.copyWith(
        color: primary, fontWeight: FontWeight.w700,
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
  // Generado desde el seed de marca (ColorScheme.fromSeed) y afinado con
  // copyWith para conservar los tonos oscuros ya validados (sin negros
  // lavados) y los roles semánticos custom (warning, info, alert).
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: brandGreen,
    brightness: Brightness.dark,
  ).copyWith(
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
    tertiaryContainer: const Color(0xFF4A3312),
    onTertiaryContainer: const Color(0xFFFFDDA6),
    error: alertRedLight,
    onError: Colors.white,
    errorContainer: const Color(0xFF4A1616),
    onErrorContainer: const Color(0xFFFFB4AB),
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
    surfaceContainerLowest: bgDark,
    surfaceContainerLow: surfaceDark,
    surfaceContainer: cardDark,
    surfaceContainerHigh: cardInnerDark,
    surfaceContainerHighest: const Color(0xFF313B34),
  );

  // ── ColorScheme light ─────────────────────────────────────────────────────
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: brandGreen,
    brightness: Brightness.light,
  ).copyWith(
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
    tertiaryContainer: const Color(0xFFFFE4B8),
    onTertiaryContainer: const Color(0xFF4A3312),
    error: alertRed,
    onError: Colors.white,
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
    surface: surfaceLight,
    onSurface: textPrimaryLight,
    onSurfaceVariant: textSecondaryLight,
    outline: const Color(0xFFCDD8CE),
    outlineVariant: const Color(0xFFE0EAE2),
    shadow: const Color(0x1A000000),
    scrim: const Color(0x80000000),
    inverseSurface: surfaceDark,
    onInverseSurface: textPrimaryDark,
    inversePrimary: brandGreenLight,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: bgLight,
    surfaceContainer: cardLight,
    surfaceContainerHigh: cardInnerLight,
    surfaceContainerHighest: const Color(0xFFE3EFE5),
  );

  // ── Shared button/shape helpers ──────────────────────────────────────────
  static RoundedRectangleBorder get _buttonShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      );

  static TextStyle _buttonTextStyle({FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: weight,
        letterSpacing: 0.3,
      );

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkScheme,
      textTheme: _buildTextTheme(textPrimaryDark, textSecondaryDark),
      scaffoldBackgroundColor: bgDark,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: brandGreen,
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
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: brandGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
          shape: _buttonShape,
          textStyle: _buttonTextStyle(),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: _buttonShape,
          textStyle: _buttonTextStyle(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandGreen,
          side: const BorderSide(color: brandGreen, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: _buttonShape,
          textStyle: _buttonTextStyle(weight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: cardDark,
          foregroundColor: textSecondaryDark,
          selectedBackgroundColor: brandGreen,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: borderDark, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 13, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: borderDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: alertRedLight, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: alertRedLight, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
        prefixIconColor: textSecondaryDark,
        suffixIconColor: textSecondaryDark,
        labelStyle: GoogleFonts.spaceGrotesk(color: textSecondaryDark),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        elevation: 3,
        surfaceTintColor: brandGreen,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        indicatorColor: brandGreen.withValues(alpha: 0.22),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: brandGreen);
          }
          return const IconThemeData(color: textHintDark);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.spaceGrotesk(fontSize: 11);
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
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 0.5,
        space: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: brandGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimaryDark, fontSize: 18, fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.spaceGrotesk(
          color: textSecondaryDark, fontSize: 14,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: brandGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimaryDark, fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: brandGreen,
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
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: brandGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
          shape: _buttonShape,
          textStyle: _buttonTextStyle(),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: _buttonShape,
          textStyle: _buttonTextStyle(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandGreenDark,
          side: const BorderSide(color: brandGreen, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: _buttonShape,
          textStyle: _buttonTextStyle(weight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandGreenDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: cardLight,
          foregroundColor: textSecondaryLight,
          selectedBackgroundColor: brandGreen,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE0EAE2), width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 13, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        hintStyle: GoogleFonts.spaceGrotesk(
          color: textHintLight,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFFCDD8CE), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: alertRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: alertRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
        prefixIconColor: textSecondaryLight,
        suffixIconColor: textSecondaryLight,
        labelStyle: GoogleFonts.spaceGrotesk(color: textSecondaryLight),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        elevation: 3,
        surfaceTintColor: brandGreen,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        indicatorColor: brandGreen.withValues(alpha: 0.16),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: brandGreenDark);
          }
          return const IconThemeData(color: textHintLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.spaceGrotesk(fontSize: 11);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: brandGreenDark, fontWeight: FontWeight.w700,
            );
          }
          return base.copyWith(color: textHintLight);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cardLight,
        selectedColor: brandGreen.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 12, fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: Color(0xFFE0EAE2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0EAE2),
        thickness: 0.5,
        space: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: brandGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimaryLight, fontSize: 18, fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.spaceGrotesk(
          color: textSecondaryLight, fontSize: 14,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: brandGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryLight,
        contentTextStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white, fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandGreen,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandGreen;
          return const Color(0xFFCDD8CE);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brandGreen.withValues(alpha: 0.4);
          }
          return const Color(0xFFE0EAE2);
        }),
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

  static LinearGradient cardGradient(bool isDark) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [cardDark, cardInnerDark.withValues(alpha: 0.8)]
            : [cardLight, cardInnerLight.withValues(alpha: 0.8)],
      );
}

/// Extensiones de contexto para acceso rápido al tema.
/// Los getters semánticos (bg, card, border, textSecondary, etc.) resuelven
/// automáticamente al tono claro u oscuro según el ThemeMode activo.
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg            => isDark ? AppTheme.bgDark : AppTheme.bgLight;
  Color get surface        => isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
  Color get card           => isDark ? AppTheme.cardDark : AppTheme.cardLight;
  Color get cardInner      => isDark ? AppTheme.cardInnerDark : AppTheme.cardInnerLight;
  Color get border         => isDark ? AppTheme.borderDark : AppTheme.borderLight;
  Color get textPrimary    => isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
  Color get textSecondary  => isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
  Color get textHint       => isDark ? AppTheme.textHintDark : AppTheme.textHintLight;
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
