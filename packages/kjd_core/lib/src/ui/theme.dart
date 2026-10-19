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
      scrolledUnderElevation: 3,
      shadowColor: const Color(0x55000000),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontFamilyFallback: kjdFontFallback,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: dark ? 0 : 1.5,
      shadowColor: const Color(0x33B26A00),
      surfaceTintColor: Colors.transparent,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      floatingLabelStyle: TextStyle(color: dark ? KjdColors.saffronLight : KjdColors.kumkum, fontWeight: FontWeight.w700),
      prefixIconColor: dark ? KjdColors.saffronLight : KjdColors.saffron,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dark ? KjdColors.saffronLight : KjdColors.saffron, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFE8D5B5)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      selectedColor: dark ? const Color(0xFF5A3A1A) : KjdColors.goldLight,
      side: BorderSide(color: dark ? Colors.white24 : const Color(0xFFEBD7B8)),
      labelStyle: TextStyle(
        color: dark ? Colors.white : KjdColors.ink,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: kjdFontFallback,
      ),
      secondaryLabelStyle: TextStyle(
        color: dark ? Colors.white : KjdColors.kumkumDark,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: kjdFontFallback,
      ),
      checkmarkColor: dark ? Colors.white : KjdColors.kumkum,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: dark ? KjdColors.saffronLight : KjdColors.kumkum,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: dark ? Colors.white12 : const Color(0xFFF1E4CE), space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF3A2A20) : KjdColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? const Color(0xFF2A1D16) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? const Color(0xFF2A1D16) : Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: KjdColors.goldLight,
      backgroundColor: dark ? const Color(0xFF1E1410) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? KjdColors.kumkum : (dark ? Colors.white70 : KjdColors.inkMuted),
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? KjdColors.kumkum : (dark ? Colors.white70 : KjdColors.inkMuted),
            fontFamilyFallback: kjdFontFallback,
          )),
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

/// Flutter font family for a [BannerTemplate.fonts] key (bundled in this package).
String bannerFontFamily(String key) => switch (key) {
      'yatraOne' => 'packages/kjd_core/YatraOne',
      'tiroMarathi' => 'packages/kjd_core/TiroDevanagariMarathi',
      'palanquinDark' => 'packages/kjd_core/PalanquinDark',
      'martel' => 'packages/kjd_core/Martel',
      'sahitya' => 'packages/kjd_core/Sahitya',
      'khand' => 'packages/kjd_core/Khand',
      'kalam' => 'packages/kjd_core/Kalam',
      'rozhaOne' => 'packages/kjd_core/RozhaOne',
      'modak' => 'packages/kjd_core/Modak',
      'laila' => 'packages/kjd_core/Laila',
      'amita' => 'packages/kjd_core/Amita',
      _ => 'packages/kjd_core/Mukta',
    };

/// Shaping language for banner text. Marathi (`mr`) is the content language,
/// but several Devanagari fonts (Yatra One, Martel, Sahitya, Amita…) switch
/// to old-style letterforms under their Marathi `locl` rules and split
/// conjuncts with visible halants ("हार्‌दिक", "क्‌षमा"). The standard forms
/// used in modern Marathi print come from the default Devanagari shaping,
/// which Hindi selects.
const bannerTextLocale = Locale('hi');
