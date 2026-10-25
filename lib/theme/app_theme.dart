import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Tema global de Turco (Material 3 + Poppins).
///
/// Paleta basada en la guía de estilo del diseño con pequeños ajustes de tono.
/// Las pantallas y widgets toman SIEMPRE los colores del [ColorScheme] y los
/// radios/espacios de [TurcoTokens]; no hay colores fijos en los widgets.
class AppTheme {
  AppTheme._();

  static const Color semilla = Color(0xFF0B6E66);
  static const String fuente = 'Poppins';

  static final ColorScheme _claro = ColorScheme.fromSeed(seedColor: semilla).copyWith(
    primary: const Color(0xFF0B6E66),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFA3EFE6),
    onPrimaryContainer: const Color(0xFF00211E),
    secondary: const Color(0xFF4A6360),
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFCFE7E3),
    onSecondaryContainer: const Color(0xFF06201D),
    tertiary: const Color(0xFF4A5F7E),
    onTertiary: const Color(0xFFFFFFFF),
    tertiaryContainer: const Color(0xFFD2E4FF),
    onTertiaryContainer: const Color(0xFF041C35),
    error: const Color(0xFFB3261E),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFF9DEDC),
    onErrorContainer: const Color(0xFF410E0B),
    surface: const Color(0xFFF5FAF9),
    onSurface: const Color(0xFF171D1C),
    onSurfaceVariant: const Color(0xFF3E4947),
    outline: const Color(0xFF6D7A78),
    outlineVariant: const Color(0xFFBDC9C6),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFEFF5F3),
    surfaceContainer: const Color(0xFFE7EFED),
    surfaceContainerHigh: const Color(0xFFE1E9E7),
    surfaceContainerHighest: const Color(0xFFDBE4E2),
    inverseSurface: const Color(0xFF2C3231),
    onInverseSurface: const Color(0xFFECF2F0),
    inversePrimary: const Color(0xFF5AD6C8),
  );

  static final ColorScheme _oscuro = ColorScheme.fromSeed(seedColor: semilla, brightness: Brightness.dark).copyWith(
    primary: const Color(0xFF5AD6C8),
    onPrimary: const Color(0xFF003732),
    primaryContainer: const Color(0xFF04504A),
    onPrimaryContainer: const Color(0xFFA3EFE6),
    secondary: const Color(0xFFB1CCC8),
    onSecondary: const Color(0xFF1C3532),
    secondaryContainer: const Color(0xFF334B48),
    onSecondaryContainer: const Color(0xFFCFE7E3),
    tertiary: const Color(0xFFB0C9E9),
    onTertiary: const Color(0xFF1A314D),
    tertiaryContainer: const Color(0xFF324865),
    onTertiaryContainer: const Color(0xFFD2E4FF),
    error: const Color(0xFFF2B8B5),
    onError: const Color(0xFF601410),
    errorContainer: const Color(0xFF8C1D18),
    onErrorContainer: const Color(0xFFF9DEDC),
    surface: const Color(0xFF0F1514),
    onSurface: const Color(0xFFDDE4E2),
    onSurfaceVariant: const Color(0xFFBDC9C6),
    outline: const Color(0xFF889391),
    outlineVariant: const Color(0xFF3E4947),
    surfaceContainerLowest: const Color(0xFF0A0F0E),
    surfaceContainerLow: const Color(0xFF171D1C),
    surfaceContainer: const Color(0xFF1B2120),
    surfaceContainerHigh: const Color(0xFF252B2A),
    surfaceContainerHighest: const Color(0xFF303635),
    inverseSurface: const Color(0xFFDDE4E2),
    onInverseSurface: const Color(0xFF2C3231),
    inversePrimary: const Color(0xFF0B6E66),
  );

  static ThemeData get claro => _construir(_claro);
  static ThemeData get oscuro => _construir(_oscuro);

  static TextTheme _texto(ColorScheme cs) {
    TextStyle s(double size, FontWeight w, {double? height}) =>
        TextStyle(fontFamily: fuente, fontSize: size, fontWeight: w, height: height, color: cs.onSurface);
    return TextTheme(
      displaySmall: s(32, FontWeight.w600),
      headlineMedium: s(26, FontWeight.w600),
      headlineSmall: s(24, FontWeight.w600),
      titleLarge: s(22, FontWeight.w600),
      titleMedium: s(16, FontWeight.w500),
      titleSmall: s(14, FontWeight.w600),
      bodyLarge: s(16, FontWeight.w400),
      bodyMedium: s(14, FontWeight.w400, height: 1.45),
      bodySmall: s(12, FontWeight.w400),
      labelLarge: s(14, FontWeight.w600),
      labelMedium: s(12, FontWeight.w500),
      labelSmall: s(11, FontWeight.w500),
    );
  }

  static ThemeData _construir(ColorScheme cs) {
    final texto = _texto(cs);
    const tokens = TurcoTokens.base;
    final radioBoton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radioBoton));
    final radioCampo = BorderRadius.circular(tokens.radioCampo);

    OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: radioCampo,
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: fuente,
      textTheme: texto,
      scaffoldBackgroundColor: cs.surface,
      extensions: const [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: tokens.m,
        titleTextStyle: texto.titleLarge?.copyWith(fontSize: 20),
        iconTheme: IconThemeData(color: cs.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: cs.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, tokens.altoBoton),
          shape: radioBoton,
          textStyle: texto.labelLarge,
          padding: EdgeInsets.symmetric(horizontal: tokens.l + 4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, tokens.altoBoton),
          shape: radioBoton,
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline),
          textStyle: texto.labelLarge,
          padding: EdgeInsets.symmetric(horizontal: tokens.l + 4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: texto.labelLarge, shape: radioBoton),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: borde(cs.outline),
        enabledBorder: borde(cs.outline),
        focusedBorder: borde(cs.primary, 2),
        errorBorder: borde(cs.error, 2),
        focusedErrorBorder: borde(cs.error, 2),
        contentPadding: EdgeInsets.symmetric(horizontal: tokens.l, vertical: tokens.l),
        labelStyle: texto.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        hintStyle: texto.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        errorStyle: texto.bodySmall?.copyWith(color: cs.error),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        errorMaxLines: 2,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radioChip)),
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: cs.surface,
        selectedColor: cs.secondaryContainer,
        checkmarkColor: cs.onSecondaryContainer,
        labelStyle: texto.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
        secondaryLabelStyle: texto.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: cs.onSecondaryContainer,
        ),
        padding: EdgeInsets.symmetric(horizontal: tokens.xs),
        showCheckmark: true,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(texto.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
          side: WidgetStatePropertyAll(BorderSide(color: cs.outline)),
          visualDensity: VisualDensity.standard,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.secondaryContainer,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => texto.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? cs.onSecondaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radioTarjeta)),
        extendedTextStyle: texto.labelLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: texto.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: cs.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radioChip)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radioDialogo)),
        titleTextStyle: texto.titleLarge,
        contentTextStyle: texto.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        iconColor: cs.error,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: cs.outlineVariant,
        dragHandleSize: const Size(36, 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radioDialogo))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radioCampo)),
        textStyle: texto.bodyLarge,
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(iconColor: cs.onSurfaceVariant, titleTextStyle: texto.bodyLarge),
    );
  }
}

/// Tokens de diseño (espacios y radios) disponibles desde el tema:
/// `Theme.of(context).extension<TurcoTokens>()!` o `context.tokens`.
@immutable
class TurcoTokens extends ThemeExtension<TurcoTokens> {
  const TurcoTokens({
    this.xs = 4,
    this.s = 8,
    this.m = 12,
    this.l = 16,
    this.xl = 24,
    this.radioTarjeta = 16,
    this.radioResumen = 14,
    this.radioCampo = 12,
    this.radioFranja = 10,
    this.radioChip = 8,
    this.radioDialogo = 28,
    this.radioBoton = 23,
    this.altoBoton = 46,
  });

  static const TurcoTokens base = TurcoTokens();

  final double xs, s, m, l, xl;
  final double radioTarjeta, radioResumen, radioCampo, radioFranja, radioChip, radioDialogo, radioBoton;
  final double altoBoton;

  @override
  TurcoTokens copyWith() => this;

  @override
  TurcoTokens lerp(ThemeExtension<TurcoTokens>? other, double t) => this;
}

/// Colores de estado tomados del [ColorScheme] (nada fijo).
class ColoresEstado {
  const ColoresEstado(this.fondo, this.texto, this.barra);
  final Color fondo, texto, barra;

  static ColoresEstado de(EstadoTurno e, ColorScheme cs) => switch (e) {
    EstadoTurno.programado => ColoresEstado(cs.primaryContainer, cs.onPrimaryContainer, cs.primary),
    EstadoTurno.completado => ColoresEstado(cs.tertiaryContainer, cs.onTertiaryContainer, cs.tertiary),
    EstadoTurno.cancelado => ColoresEstado(cs.errorContainer, cs.onErrorContainer, cs.error),
  };
}

extension TemaContexto on BuildContext {
  ThemeData get tema => Theme.of(this);
  ColorScheme get colores => Theme.of(this).colorScheme;
  TextTheme get textos => Theme.of(this).textTheme;
  TurcoTokens get tokens => Theme.of(this).extension<TurcoTokens>() ?? TurcoTokens.base;
}
