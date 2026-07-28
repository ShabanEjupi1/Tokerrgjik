import 'package:flutter/material.dart';

/// Ngjyrat e lojës.
///
/// Paleta është e guralecit dhe e dheut — qymyr i ngrohtë, ranor, terrakotë —
/// sepse kjo lojë luhej mbi tokë me gurë, jo mbi një ekran blu. Aplikacioni i
/// vjetër kishte një gradient vjollcë-blu të marrë nga një shabllon; ai nuk i
/// thoshte asgjë askujt.
abstract final class Palette {
  static const Color ink = Color(0xFF1B1713);
  static const Color surface = Color(0xFF241E19);
  static const Color surfaceHigh = Color(0xFF2E2721);
  static const Color line = Color(0xFF6B5C4C);
  static const Color text = Color(0xFFEFE6DC);
  static const Color textDim = Color(0xFFB8A894);
  static const Color accent = Color(0xFFD98B45);
  static const Color accentDeep = Color(0xFFB4652F);

  /// Guri i bardhë dhe guri i zi. "I zi" është terrakotë e ngrohtë: dy gurë të
  /// vërtetë mbi dhe nuk janë kurrë bardhë e zi, dhe kontrasti lexohet më mirë
  /// mbi tabelën e errët sesa një i zi i vërtetë.
  static const Color stoneWhite = Color(0xFFF2EADF);
  static const Color stoneBlack = Color(0xFFC2682D);

  static const Color good = Color(0xFF7FA860);
  static const Color danger = Color(0xFFC4553F);
}

ThemeData buildTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: Palette.accent,
    brightness: Brightness.dark,
  ).copyWith(
    surface: Palette.ink,
    primary: Palette.accent,
    secondary: Palette.accentDeep,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.ink,
    fontFamily: null,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.ink,
      foregroundColor: Palette.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: Palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.accent,
        foregroundColor: Palette.ink,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.text,
        side: const BorderSide(color: Palette.line),
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.surfaceHigh,
      contentTextStyle: TextStyle(color: Palette.text),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
