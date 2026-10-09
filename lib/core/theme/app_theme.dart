import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/theme/bf_typography.dart';

/// Central Break Free theme. Prefer tokens in [BfColors] / [BfSpacing] / [BfRadius]
/// over one-off values in screens.
class AppTheme {
  // Backward-compatible aliases used by older screens.
  static const Color primaryDark = BfColors.accentMuted;
  static const Color primary = BfColors.accent;
  static const Color accent = BfColors.accent;
  static const Color surfaceLight = BfColors.paper;
  static const Color surfaceDark = BfColors.ink;
  static const Color cardLight = BfColors.paperElevated;
  static const Color cardDark = BfColors.inkElevated;

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: BfColors.accent,
      onPrimary: Colors.white,
      secondary: BfColors.accentMuted,
      onSecondary: Colors.white,
      error: BfColors.danger,
      onError: Colors.white,
      surface: dark ? BfColors.ink : BfColors.paper,
      onSurface: dark ? BfColors.textPrimaryDark : BfColors.textPrimaryLight,
      surfaceContainerHighest: dark ? BfColors.inkSoft : BfColors.paperSoft,
      outline: dark ? BfColors.borderDark : BfColors.borderLight,
      outlineVariant: dark ? BfColors.inkMuted : const Color(0xFFE0DDD6),
    );

    final text = BfTypography.textTheme(dark: dark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: scheme.outline,
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? BfColors.inkElevated : BfColors.paperElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BfRadius.md),
          side: BorderSide(color: scheme.outline),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: BfSpacing.md),
        iconColor: dark ? BfColors.textSecondaryDark : BfColors.textSecondaryLight,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: BfSpacing.sm,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: BfColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BfColors.accent.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: BfSpacing.xl, vertical: BfSpacing.md),
          minimumSize: const Size(64, BfSpacing.minTouch),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BfRadius.md)),
          textStyle: text.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: BfColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: BfSpacing.xl, vertical: BfSpacing.md),
          minimumSize: const Size(64, BfSpacing.minTouch),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BfRadius.md)),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: BfSpacing.xl, vertical: BfSpacing.md),
          minimumSize: const Size(64, BfSpacing.minTouch),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BfRadius.md)),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? BfColors.textSecondaryDark : BfColors.textSecondaryLight,
          textStyle: text.labelLarge,
          minimumSize: const Size(48, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? BfColors.inkSoft : BfColors.paperSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BfRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BfRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BfRadius.md),
          borderSide: const BorderSide(color: BfColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: BfSpacing.md, vertical: BfSpacing.md),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? BfColors.inkSoft : BfColors.paperSoft,
        selectedColor: BfColors.accentSoft,
        side: BorderSide(color: scheme.outline),
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: BfSpacing.xs, vertical: BfSpacing.xxs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BfRadius.sm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? BfColors.inkElevated : BfColors.paperElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BfRadius.lg),
          side: BorderSide(color: scheme.outline),
        ),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? BfColors.inkElevated : BfColors.paperElevated,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(BfRadius.lg)),
        ),
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        backgroundColor: dark ? BfColors.ink : BfColors.paper,
        indicatorColor: BfColors.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            color: selected
                ? BfColors.accent
                : (dark ? BfColors.textTertiaryDark : BfColors.textTertiaryLight),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected
                ? BfColors.accent
                : (dark ? BfColors.textTertiaryDark : BfColors.textTertiaryLight),
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? BfColors.inkSoft : BfColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: BfColors.textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BfRadius.sm)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BfColors.accent,
        linearTrackColor: BfColors.accentSoft,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? BfColors.accent : null,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: BfColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
