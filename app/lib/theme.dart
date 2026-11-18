import 'package:flutter/material.dart';

/// Cores fixas do app (independentes do tema).
class Cores {
  static const primaria = Color(0xFF1E4FD8);
  static const fundo = Color(0xFFF4F6FA);
  static const borda = Color(0xFFE3E7EF);
  static const textoSecundario = Color(0xFF64748B);

  static const aprovar = Color(0xFF16A34A);
  static const aprovarClaro = Color(0xFFDCFCE7);
  static const rejeitar = Color(0xFFDC2626);
  static const rejeitarClaro = Color(0xFFFEE2E2);
  static const alerta = Color(0xFFD97706);
  static const alertaClaro = Color(0xFFFEF3C7);
}

ThemeData temaClaro() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Cores.primaria,
    brightness: Brightness.light,
  ).copyWith(
    primary: Cores.primaria,
    surface: Colors.white,
    error: Cores.rejeitar,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: Brightness.light);

  return base.copyWith(
    scaffoldBackgroundColor: Cores.fundo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Cores.borda),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Cores.borda, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Cores.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Cores.borda),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

ButtonStyle botaoAprovar() => FilledButton.styleFrom(
      backgroundColor: Cores.aprovar,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Cores.aprovar.withValues(alpha: 0.45),
      disabledForegroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
    );

ButtonStyle botaoRejeitar() => FilledButton.styleFrom(
      backgroundColor: Cores.rejeitar,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Cores.rejeitar.withValues(alpha: 0.45),
      disabledForegroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
    );
