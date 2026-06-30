import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/utils/simulator_detector.dart';
import '../widgets/onboarding_tokens.dart';

/// 일괄 요청 대상 권한.
enum OnbPermKind { camera, microphone, notification }

/// 권한 정책 — 나중에 쉽게 바꾸도록 한 곳에 모음.
abstract final class OnboardingPermissionConfig {
  /// 거부 시 진행(홈 이동)을 막는 **필수** 권한.
  static const Set<OnbPermKind> requiredKinds = {
    OnbPermKind.camera,
    OnbPermKind.microphone,
  };

  /// 화면에 노출하는 순서.
  static const List<OnbPermKind> shown = [
    OnbPermKind.camera,
    OnbPermKind.microphone,
    OnbPermKind.notification,
  ];

  static bool isRequired(OnbPermKind k) => requiredKinds.contains(k);
}

enum _PermStatus { unknown, granted, denied, permanentlyDenied }

/// 온보딩 직후 1회 노출되는 일괄 권한 안내 화면.
///
/// - 카메라·마이크(필수): 모두 허용돼야 하단 CTA로 홈 이동. 영구거부면 [설정 열기] 유도.
/// - 알림(선택): 거부해도 진행 가능.
/// - web/iOS 시뮬레이터: 필수 권한을 막지 않고 통과(하드웨어/권한 개념 부재).
/// 첫 실행이라 라이트로 렌더된다(라우터가 AppTheme.light 로 감쌈).
class OnboardingPermissionsScreen extends StatefulWidget {
  const OnboardingPermissionsScreen({
    super.key,
    required this.isTutor,
    required this.onDone,
  });

  /// 역할 — 강조색/홈 목적지 결정용.
  final bool isTutor;

  /// 필수 권한 충족 후 "시작하기" 시 호출(플래그 저장 + 홈 이동은 호출측에서).
  final VoidCallback onDone;

  @override
  State<OnboardingPermissionsScreen> createState() =>
      _OnboardingPermissionsScreenState();
}

class _OnboardingPermissionsScreenState
    extends State<OnboardingPermissionsScreen> with WidgetsBindingObserver {
  final Map<OnbPermKind, _PermStatus> _status = {
    for (final k in OnbPermKind.values) k: _PermStatus.unknown,
  };
  bool _bypass = false; // web / iOS 시뮬레이터 → 필수 통과
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 설정 다녀온 뒤 허용 여부를 다시 반영.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _init() async {
    _bypass = kIsWeb || await isIosSimulator();
    await _refresh();
  }

  Future<void> _refresh() async {
    if (kIsWeb) {
      setState(() {
        for (final k in OnbPermKind.values) {
          _status[k] = _PermStatus.granted;
        }
      });
      return;
    }
    final cam = _map(await Permission.camera.status);
    final mic = _map(await Permission.microphone.status);
    final noti = await AppNotificationService.instance.hasPermission();
    if (!mounted) return;
    setState(() {
      _status[OnbPermKind.camera] =
          _bypass ? _PermStatus.granted : cam;
      _status[OnbPermKind.microphone] =
          _bypass ? _PermStatus.granted : mic;
      _status[OnbPermKind.notification] =
          noti ? _PermStatus.granted : _status[OnbPermKind.notification]!;
    });
  }

  static _PermStatus _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return _PermStatus.granted;
    if (s.isPermanentlyDenied || s.isRestricted) {
      return _PermStatus.permanentlyDenied;
    }
    return _PermStatus.denied;
  }

  Future<void> _request(OnbPermKind kind) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_bypass && kind != OnbPermKind.notification) {
        setState(() => _status[kind] = _PermStatus.granted);
        return;
      }
      if (kind == OnbPermKind.notification) {
        final granted =
            await AppNotificationService.instance.requestPermission();
        if (!mounted) return;
        setState(() => _status[kind] =
            granted ? _PermStatus.granted : _PermStatus.denied);
        return;
      }
      final permission =
          kind == OnbPermKind.camera ? Permission.camera : Permission.microphone;
      final result = _map(await permission.request());
      if (!mounted) return;
      setState(() => _status[kind] = result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openSettings() => AppNotificationService.instance.openSystemSettings();

  bool get _requiredAllGranted =>
      _bypass ||
      OnboardingPermissionConfig.requiredKinds
          .every((k) => _status[k] == _PermStatus.granted);

  @override
  Widget build(BuildContext context) {
    final p = OnbPalette.of(context);
    final role =
        widget.isTutor ? OnbRolePalette.tutor : OnbRolePalette.student;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                '권한 허용',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '온샘을 제대로 쓰려면 아래 권한이 필요해요.\n수업을 위해 카메라·마이크는 꼭 허용해 주세요.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: p.textSub,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: [
                    for (final kind in OnboardingPermissionConfig.shown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PermRow(
                          palette: p,
                          accent: role.point,
                          icon: _iconFor(kind),
                          title: _titleFor(kind),
                          desc: _descFor(kind),
                          required: OnboardingPermissionConfig.isRequired(kind),
                          status: _status[kind]!,
                          onAllow: _busy ? null : () => _request(kind),
                          onOpenSettings: _openSettings,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (!_requiredAllGranted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '수업을 들으려면 카메라·마이크 권한이 필요해요.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.textDim,
                    ),
                  ),
                ),
              _StartButton(
                label: '시작하기',
                color: role.point,
                labelColor: role.onPoint,
                enabled: _requiredAllGranted,
                disabledColor: p.line,
                disabledLabelColor: p.textDim,
                onTap: _requiredAllGranted ? widget.onDone : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(OnbPermKind k) => switch (k) {
        OnbPermKind.camera => Icons.videocam_outlined,
        OnbPermKind.microphone => Icons.mic_none_rounded,
        OnbPermKind.notification => Icons.notifications_none_rounded,
      };

  static String _titleFor(OnbPermKind k) => switch (k) {
        OnbPermKind.camera => '카메라',
        OnbPermKind.microphone => '마이크',
        OnbPermKind.notification => '알림 (선택)',
      };

  static String _descFor(OnbPermKind k) => switch (k) {
        OnbPermKind.camera => '수업 중 얼굴이나 문제를 보여줄 때 사용해요.',
        OnbPermKind.microphone => '실시간 수업에서 목소리를 주고받아요.',
        OnbPermKind.notification => '수업·매칭 소식을 놓치지 않게 알려드려요.',
      };
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.palette,
    required this.accent,
    required this.icon,
    required this.title,
    required this.desc,
    required this.required,
    required this.status,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final OnbPalette palette;
  final Color accent;
  final IconData icon;
  final String title;
  final String desc;
  final bool required;
  final _PermStatus status;
  final VoidCallback? onAllow;
  final VoidCallback onOpenSettings;

  static const Color _granted = Color(0xFF2E9E6B);

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: p.textSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _trailing(p),
        ],
      ),
    );
  }

  Widget _trailing(OnbPalette p) {
    if (status == _PermStatus.granted) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Icon(Icons.check_circle_rounded, color: _granted, size: 24),
      );
    }
    // 필수 권한이 영구거부면 설정으로 유도(선택 권한은 그냥 다시 허용 시도).
    if (status == _PermStatus.permanentlyDenied && required) {
      return _pill(
        label: '설정 열기',
        onTap: onOpenSettings,
        filled: false,
        accent: accent,
        palette: p,
      );
    }
    return _pill(
      label: '허용',
      onTap: onAllow,
      filled: true,
      accent: accent,
      palette: p,
    );
  }

  Widget _pill({
    required String label,
    required VoidCallback? onTap,
    required bool filled,
    required Color accent,
    required OnbPalette palette,
  }) {
    return Material(
      color: filled ? accent : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: accent, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              // 채움 버튼(밝은 포인트색) 위엔 어두운 글자가 잘 보임.
              color: filled ? const Color(0xFF2A2E1A) : accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.label,
    required this.color,
    required this.labelColor,
    required this.enabled,
    required this.disabledColor,
    required this.disabledLabelColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color labelColor;
  final bool enabled;
  final Color disabledColor;
  final Color disabledLabelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled ? color : disabledColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: enabled ? labelColor : disabledLabelColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
