import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';

class StudentMyPageScreen extends ConsumerWidget {
  const StudentMyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ShellTheme.of(context);

    return ColoredBox(
      color: shell.scaffoldBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '마이페이지',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: shell.titleColor,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => ref
                              .read(shellDarkModeProvider.notifier)
                              .update((v) => !v),
                          icon: Icon(
                            ref.watch(shellDarkModeProvider)
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 22,
                          ),
                          color: Theme.of(context).colorScheme.secondary,
                          tooltip: ref.watch(shellDarkModeProvider)
                              ? '라이트 모드'
                              : '다크 모드',
                          splashRadius: 18,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => context.go(RoutePaths.login),
                          icon: const Icon(
                            Icons.logout_outlined,
                            size: 22,
                          ),
                          color: const Color(0xFFE53935),
                          tooltip: '로그아웃',
                          splashRadius: 18,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  '준비 중입니다',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: shell.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
