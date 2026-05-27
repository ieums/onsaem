import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';

class ShellTheme {
  ShellTheme._(this._context);

  final BuildContext _context;

  static ShellTheme of(BuildContext context) => ShellTheme._(context);

  ColorScheme get _scheme => Theme.of(_context).colorScheme;

  Color get scaffoldBackground => Theme.of(_context).scaffoldBackgroundColor;
  Color get cardBackground => _scheme.surface;
  Color get cardBorder => _scheme.outline;
  Color get menuSheetBackground => _scheme.surface;
  Color get detailBackground => _scheme.surfaceContainerHighest;
  Color get borderColor => _scheme.outline;
  Color get dividerColor => Theme.of(_context).dividerColor;
  Color get iconBackground => _scheme.surfaceContainerHigh;
  Color get titleColor => _scheme.onSurface;
  Color get subtitleColor => _scheme.secondary;
  Color get hintColor => _scheme.onSurfaceVariant;
  Color get chevronColor => _scheme.onSurfaceVariant;
  Color get trackOffColor => _scheme.surfaceContainerLow;
  Color get offlineButtonColor => _scheme.surfaceContainerHighest;
  Color get offlineButtonTextColor => _scheme.onSurfaceVariant;
  Color get dangerColor => AppColors.logoutRed;
}
