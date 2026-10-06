import 'package:flutter/material.dart';

/// Brand palette taken from the temple logo: deep kumkum red, saffron and
/// gold on warm white.
abstract final class KjdColors {
  static const kumkum = Color(0xFFB71C1C);
  static const kumkumDark = Color(0xFF7F0000);
  static const saffron = Color(0xFFF57C00);
  static const saffronLight = Color(0xFFFFB74D);
  static const gold = Color(0xFFFFC107);
  static const goldLight = Color(0xFFFFF3C4);
  static const cream = Color(0xFFFFFBF2);
  static const ink = Color(0xFF2B1A12);
  static const inkMuted = Color(0xFF6D5A4E);
  static const live = Color(0xFFD50000);
  static const success = Color(0xFF2E7D32);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kumkumDark, kumkum, saffron],
  );

  static const goldGradient = LinearGradient(colors: [Color(0xFFFFE082), gold, Color(0xFFFFA000)]);
}

const kjdFontFallback = ['Noto Sans Devanagari', 'Mukta', 'Hind', 'sans-serif'];

ThemeData buildKjdTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: KjdColors.kumkum,
    brightness: brightness,
    primary: dark ? KjdColors.saffronLight : KjdColors.kumkum,
    secondary: KjdColors.saffron,
    tertiary: KjdColors.gold,
    surface: dark ? const Color(0xFF1E1410) : KjdColors.cream,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.apply(
      fontFamilyFallback: kjdFontFallback,
      bodyColor: dark ? Colors.white : KjdColors.ink,
      displayColor: dark ? Colors.white : KjdColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF2A1A12) : KjdColors.kumkum,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontFamilyFallback: kjdFontFallback,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xFF2A1D16) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: dark ? Colors.white10 : const Color(0xFFF3E3C7)),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? Colors.white10 : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFE8D5B5)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: KjdColors.goldLight,
      backgroundColor: dark ? const Color(0xFF1E1410) : Colors.white,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamilyFallback: kjdFontFallback),
      ),
    ),
  );
}

/// The temple logo bundled in this package.
class TempleLogo extends StatelessWidget {
  const TempleLogo({super.key, this.size = 48});
  final double size;

  static const asset = AssetImage('assets/logo.png', package: 'kjd_core');

  @override
  Widget build(BuildContext context) =>
      Image(image: asset, width: size, height: size, fit: BoxFit.contain, semanticLabel: 'श्री काळभैरव जागृत देवस्थान');
}
