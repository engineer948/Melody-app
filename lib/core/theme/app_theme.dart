import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:melody/core/theme/theme_settings.dart';

/// Builds the application's themes.
///
/// Surfaces are neutral greys (optionally tinted with the accent) and the
/// accent is used as-is, so colors stay vivid instead of pastel.
abstract final class AppTheme {
  /// Theme used when the app is in light mode.
  static ThemeData light(ThemeSettings settings, {Color? systemSeed}) =>
      _build(settings, scheme(settings, Brightness.light, systemSeed));

  /// Theme used when the app is in dark mode.
  static ThemeData dark(ThemeSettings settings, {Color? systemSeed}) =>
      _build(settings, scheme(settings, Brightness.dark, systemSeed));

  /// The accent in effect: wallpaper color when chosen and available.
  static Color effectiveAccent(ThemeSettings settings, Color? systemSeed) =>
      settings.useSystemColors && systemSeed != null
      ? systemSeed
      : settings.accent;

  /// Color scheme for [brightness].
  static ColorScheme scheme(
    ThemeSettings settings,
    Brightness brightness,
    Color? systemSeed,
  ) {
    final accent = effectiveAccent(settings, systemSeed);
    final dark = brightness == Brightness.dark;
    final tonal = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final black = dark && settings.pureBlack;
    // Neutral surface ladder, lowest to highest.
    final neutral = dark
        ? black
              ? const [
                  0xFF000000,
                  0xFF000000,
                  0xFF0E0E0F,
                  0xFF161618,
                  0xFF1E1E21,
                  0xFF27272A,
                ]
              : const [
                  0xFF0B0B0C,
                  0xFF121214,
                  0xFF1A1A1D,
                  0xFF222226,
                  0xFF2A2A2F,
                  0xFF34343A,
                ]
        : const [
            0xFFFFFFFF,
            0xFFFFFFFF,
            0xFFF7F7F8,
            0xFFF0F0F2,
            0xFFE9E9EC,
            0xFFE1E1E5,
          ];
    final tint = (black ? 0.0 : settings.tint.clamp(0.0, 1.0)) * 0.22;
    Color surface(int i) =>
        Color.alphaBlend(accent.withValues(alpha: tint), Color(neutral[i]));
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return tonal.copyWith(
      primary: accent,
      onPrimary: onAccent,
      surface: surface(1),
      surfaceDim: surface(0),
      surfaceBright: surface(3),
      surfaceContainerLowest: surface(0),
      surfaceContainerLow: surface(2),
      surfaceContainer: surface(3),
      surfaceContainerHigh: surface(4),
      surfaceContainerHighest: surface(5),
      onSurface: dark ? const Color(0xFFF5F5F7) : const Color(0xFF111113),
      onSurfaceVariant: dark
          ? const Color(0xFFA1A1A8)
          : const Color(0xFF6B6B73),
      outlineVariant: dark ? const Color(0xFF2E2E33) : const Color(0xFFDCDCE0),
      surfaceTint: Colors.transparent,
    );
  }

  static TextTheme _text(TextTheme base) => base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  );

  static ThemeData _build(ThemeSettings settings, ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: settings.font.family,
    );
    final selected = WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.selected)
          ? scheme.primary
          : scheme.onSurfaceVariant,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _text(base.textTheme),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _text(base.textTheme).titleLarge
            ?.copyWith(color: scheme.onSurface),
      ),
      // No pill behind the selected destination: the icon and label take
      // the accent color; a press shows a short ripple that fades away.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: selected.resolve(states), size: 26),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => base.textTheme.labelSmall?.copyWith(
            color: selected.resolve(states),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.5,
        space: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // Selected controls use the accent itself, never a pale tone.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
