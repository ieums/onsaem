import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_fonts.dart';

/// 강사·학생 탭 다크 모드 on/off (로그인·온보딩에는 미적용)
final shellDarkModeProvider = StateProvider<bool>((ref) => false);

abstract final class AppTheme {
  static ThemeData _withFont(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: AppFonts.pretendard),
      primaryTextTheme:
          theme.primaryTextTheme.apply(fontFamily: AppFonts.pretendard),
    );
  }

  /// 로그인·온보딩·회원가입
  static ThemeData get light => _withFont(
        ThemeData(
          fontFamily: AppFonts.pretendard,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            primary: AppColors.primaryBlue,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
        ),
      );

  /// 강사·학생 탭
  static ThemeData shell(Brightness brightness) => _shellTheme(brightness);

  static ThemeData get shellLight => shell(Brightness.light);

  static ThemeData get shellDark => shell(Brightness.dark);

  static ThemeData _shellTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primaryBlue,
            onPrimary: AppColors.shellOnSurfaceLight,
            secondary: AppColors.shellSubtitleDark,
            surface: AppColors.shellSurfaceDark,
            onSurface: AppColors.shellOnSurfaceDark,
            onSurfaceVariant: AppColors.shellHintDark,
            outline: AppColors.shellCardBorderDark,
            surfaceContainerHighest: AppColors.shellDetailDark,
            surfaceContainerHigh: AppColors.shellIconBgDark,
            surfaceContainerLow: AppColors.shellTrackOffDark,
          )
        : ColorScheme.light(
            primary: AppColors.primaryBlue,
            onPrimary: AppColors.white,
            secondary: AppColors.shellSubtitleLight,
            surface: AppColors.shellSurfaceLight,
            onSurface: AppColors.shellOnSurfaceLight,
            onSurfaceVariant: AppColors.shellHintLight,
            outline: AppColors.shellCardBorderLight,
            surfaceContainerHighest: AppColors.shellDetailLight,
            surfaceContainerHigh: AppColors.shellIconBgLight,
            surfaceContainerLow: AppColors.shellTrackOffLight,
          );

    return _withFont(ThemeData(
      fontFamily: AppFonts.pretendard,
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.shellScaffoldDark
          : AppColors.shellScaffoldLight,
      dividerColor:
          isDark ? AppColors.shellDividerDark : AppColors.shellDividerLight,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.shellScaffoldDark
            : AppColors.shellScaffoldLight,
        foregroundColor: isDark
            ? AppColors.shellOnSurfaceDark
            : AppColors.shellOnSurfaceLight,
        iconTheme: IconThemeData(
          color: isDark
              ? AppColors.shellOnSurfaceDark
              : AppColors.shellOnSurfaceLight,
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.shellOnSurfaceDark
              : AppColors.shellOnSurfaceLight,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: isDark
              ? AppColors.shellOnSurfaceDark
              : AppColors.shellOnSurfaceLight,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: isDark
              ? AppColors.shellOnSurfaceDark
              : AppColors.shellOnSurfaceLight,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: isDark
              ? AppColors.shellOnSurfaceDark
              : AppColors.shellOnSurfaceLight,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: isDark
              ? AppColors.shellOnSurfaceDark
              : AppColors.shellOnSurfaceLight,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? AppColors.shellTabBarDark
            : AppColors.shellTabBarLight,
        indicatorColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.shellSnackBarDark
            : const Color(0xFF323232),
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: isDark ? AppColors.shellOnSurfaceDark : AppColors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surface : scheme.surfaceContainerHigh,
        hintStyle: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: isDark ? AppColors.white70 : scheme.onSurfaceVariant,
          fontSize: 15,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      ),
    ));
  }
}
