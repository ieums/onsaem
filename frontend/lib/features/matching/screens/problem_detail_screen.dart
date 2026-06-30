import 'package:flutter/material.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/features/student/widgets/student_problem_image_viewer.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/matching/models/searching_problem_model.dart';
import 'package:ieum/features/matching/providers/matching_provider.dart';
import 'package:ieum/features/student/providers/mypage_provider.dart';
import 'package:ieum/features/student/utils/problem_enum_labels.dart';
import 'package:ieum/features/tutor/providers/tutor_availability_provider.dart';
import 'package:ieum/features/tutor/widgets/tutor_action_button_style.dart';

class ProblemDetailScreen extends ConsumerStatefulWidget {
  const ProblemDetailScreen({super.key, required this.problem});

  final SearchingProblemModel problem;

  @override
  ConsumerState<ProblemDetailScreen> createState() =>
      _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends ConsumerState<ProblemDetailScreen> {
  bool _isApplying = false;
  bool _problemExpanded = false; // 학생이 고른 문제 글 펼침 여부

  Future<void> _apply() async {
    setState(() => _isApplying = true);
    try {
      await ref
          .read(matchingProvider.notifier)
          .applyToLesson(widget.problem.problemId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신청이 완료되었습니다')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신청에 실패했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  /// 오프라인 상태에서 신청 시도 시 안내. '온라인 전환' 누르면 켜고 바로 신청.
  Future<void> _showOfflineDialog() async {
    final goOnline = await showConfirmDialog(
      context: context,
      title: '오프라인 상태예요',
      message: '온라인으로 전환해야 학생이 선택할 수 있어요.\n지금 온라인으로 전환할까요?',
      cancelText: '닫기',
      confirmText: '온라인으로 전환',
      isTutor: true,
    );
    if (!goOnline || !mounted) return;
    await ref.read(tutorAvailabilityProvider.notifier).toggle(true);
    if (!mounted) return;
    await _apply();
  }

  @override
  Widget build(BuildContext context) {
    // 단독 라우트라 부모 shell 테마를 못 받으므로, 여기서 직접 다크/라이트 테마를 감싼다.
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.primaryBlue),
      ),
      child: Builder(builder: (context) {
        final shell = ShellTheme.of(context);
        final isOnline = ref.watch(tutorAvailabilityProvider);
        final problem = widget.problem;
        // 학력 인증 상태 — 관리자 승인(VERIFIED)된 강사만 신청 가능(백엔드에서도 차단).
        final verificationStatus =
            ref.watch(meProvider).valueOrNull?['verificationStatus'] as String?;
        // 상태를 아직 모르면(로딩 중·null) 막지 않고, 명확히 미인증일 때만 차단.
        final isVerificationBlocked =
            verificationStatus != null && verificationStatus != 'VERIFIED';
        // 오프라인이어도 버튼은 눌리게 해서 안내 다이얼로그를 띄운다.
        final canTapApply =
            !problem.alreadyApplied && !_isApplying && !isVerificationBlocked;

        return Scaffold(
      backgroundColor: shell.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: shell.scaffoldBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: shell.titleColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '문제 상세',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: shell.titleColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 문제 이미지
              _buildImageArea(problem, shell),
              const SizedBox(height: 20),

              // ① 요약 = 문제 제목처럼 맨 위 (한 줄)
              if (_oneLine(problem.summary).isNotEmpty) ...[
                Text(
                  _oneLine(problem.summary),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: shell.titleColor,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ② 학생이 고른 문제 = 실제 추출된 문제 내용(원문)
              if ((problem.extractedText ?? '').trim().isNotEmpty) ...[
                _buildSelectedProblemCard(problem, shell),
                const SizedBox(height: 16),
              ],

              // ③ 상세 정보(유형/난이도/시험유형)
              _buildInfoCard(problem, shell),
              const SizedBox(height: 16),

              // ④ 학생이 직접 쓴 설명(어려운 점 등) — 유형 아래, 있을 때만
              if ((problem.studentDescription ?? '').trim().isNotEmpty) ...[
                _buildStudentNote(problem.studentDescription!.trim(), shell),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // 학력 인증 미완료 안내 — 신청 버튼 비활성 이유를 설명.
              if (isVerificationBlocked) ...[
                _buildVerificationNotice(verificationStatus, shell),
                const SizedBox(height: 12),
              ],

              // 버튼 — 신청: 통일 아웃라인(테두리만 특징색+흰/다크 배경). 넘기기: 가볍게(텍스트 버튼).
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: !canTapApply
                          ? null
                          : (isOnline ? _apply : _showOfflineDialog),
                      style: tutorOutlinedButtonStyle(isDark, radius: 12,
                          minimumSize: const Size.fromHeight(52)),
                      child: _isApplying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : Text(
                              isVerificationBlocked
                                  ? '학력 인증 후 신청 가능'
                                  : (problem.alreadyApplied ? '이미 신청됨' : '신청'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 넘기기: 보더 없이 가벼운 텍스트 버튼.
                  TextButton(
                    onPressed: () => context.pop(problem.problemId),
                    style: TextButton.styleFrom(
                      foregroundColor: shell.hintColor,
                      // Size.fromHeight는 width=무한대 → Row에서 크래시. 높이만 고정.
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      problem.alreadyApplied ? '닫기' : '넘기기',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
        );
      }),
    );
  }

  Widget _buildSelectedProblemCard(
      SearchingProblemModel problem, ShellTheme shell) {
    // 배지: '학생이 고른 문제 · 34번 · 영어'
    final label = StringBuffer('학생이 고른 문제');
    if (problem.problemNumber != null) {
      label.write(' · ${problem.problemNumber}번');
    }
    final subj = problem.subjectLabel;
    if (subj != '-') label.write(' · $subj');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _problemBody(problem.extractedText ?? '', shell),
        ],
      ),
    );
  }

  /// OCR 본문 보기 좋게: 문장 중간에 박힌 줄바꿈은 이어 붙이고,
  /// 문단 구분(빈 줄)과 선택지(①②③④⑤)만 줄을 살린다.
  /// 길면 기본은 접힌 상태(5줄) + '더 보기/접기' 토글.
  Widget _problemBody(String raw, ShellTheme shell) {
    final text = _reflow(raw);
    // 대략적인 길이 기준 — 충분히 길 때만 토글 노출.
    final isLong = text.length > 160;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          textAlign: TextAlign.left,
          maxLines: (!isLong || _problemExpanded) ? null : 5,
          overflow: (!isLong || _problemExpanded)
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w600, // 학생 문제 상세처럼 진하게
            color: shell.titleColor,
          ),
        ),
        if (isLong)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  setState(() => _problemExpanded = !_problemExpanded),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(_problemExpanded ? '접기' : '더 보기',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }


  /// OCR 원문 reflow: 문단(빈 줄)은 보존, 문단 내부의 단순 줄바꿈은 공백으로 이어 붙여
  /// 문장 중간이 끊겨 보이는 걸 막고, 선택지(①②③④⑤)는 한 줄씩 보이게 한다.
  String _reflow(String raw) {
    final normalized = raw.replaceAll('\\n', '\n').replaceAll('\r', '');
    final paragraphs = normalized.split(RegExp(r'\n[ \t]*\n+'));
    var s = paragraphs
        .map((p) =>
            p.replaceAll('\n', ' ').replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .where((p) => p.isNotEmpty)
        .join('\n\n');
    s = s.replaceAllMapped(
      RegExp(r' *([①②③④⑤⑥⑦⑧⑨⑩])'),
      (m) => '\n${m[1]}',
    );
    return s.trim();
  }

  /// 학생이 직접 쓴 설명(어려운 점 등) 카드.
  Widget _buildStudentNote(String note, ShellTheme shell) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 16, color: shell.hintColor),
              const SizedBox(width: 4),
              Text(
                '학생이 남긴 설명',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: shell.hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: shell.titleColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 학력 인증 미완료 안내 배너 — 상태별 문구.
  Widget _buildVerificationNotice(String status, ShellTheme shell) {
    final bool rejected = status == 'REJECTED';
    final String message = rejected
        ? '학력 인증이 반려되었어요. 마이페이지에서 증빙 서류를 다시 제출해 주세요.'
        : '학력 인증 심사 중이에요. 관리자 승인 후 강의를 신청할 수 있어요.';
    final Color accent = rejected ? const Color(0xFFD9534F) : AppColors.primaryBlue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            rejected ? Icons.error_outline_rounded : Icons.verified_user_outlined,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: shell.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 리터럴 "\n"·중복 공백을 제거해 한 줄로(요약 제목용).
  String _oneLine(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll('\\n', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildImageArea(SearchingProblemModel problem, ShellTheme shell) {
    if (problem.imageUrls.isEmpty) {
      return _imagePlaceholder(shell);
    }
    // SingleChildScrollView+Column(가로 느슨)에서 단일 이미지 Stack이 0폭으로 찌부되는 걸 방지.
    return SizedBox(
      width: double.infinity,
      child: _ImagePager(urls: problem.imageUrls, shell: shell),
    );
  }

  Widget _imagePlaceholder(dynamic shell) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 40, color: shell.hintColor),
          const SizedBox(height: 8),
          Text(
            '문제 이미지 없음',
            style: TextStyle(fontSize: 14, color: shell.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(SearchingProblemModel problem, dynamic shell) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _infoRow('과목', problem.subjectLabel, shell),
          _infoRow('유형 (대)', problem.primaryType ?? '-', shell),
          _infoRow('유형 (소)', problem.secondaryType ?? '-', shell),
          _infoRow('난이도', difficultyLabel(problem.difficulty), shell),
          _infoRow('시험 유형', examTypeLabel(problem.examType), shell),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, dynamic shell) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: shell.hintColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: shell.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePager extends StatefulWidget {
  const _ImagePager({required this.urls, required this.shell});
  final List<String> urls;
  final ShellTheme shell;

  @override
  State<_ImagePager> createState() => _ImagePagerState();
}

class _ImagePagerState extends State<_ImagePager> {
  final _controller = PageController();
  int _page = 0;
  static const double _height = 220;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.length == 1) {
      return SizedBox(height: _height, child: _buildImage(context, urls.first, 0));
    }
    return Column(
      children: [
        SizedBox(
          height: _height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _buildImage(context, urls[i], i),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_page + 1}/${urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < urls.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page
                      ? AppColors.primaryBlue
                      : widget.shell.cardBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context, String url, int index) {
    final resolved = ApiConstants.resolveImageUrl(url);
    return GestureDetector(
      onTap: () => showStudentProblemImageGalleryUrls(
        context,
        imageUrls: [
          for (final u in widget.urls) ApiConstants.resolveImageUrl(u),
        ],
        initialIndex: index,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // 학생 문제 상세와 동일: 잘리지 않게 contain + 여백은 배경색으로.
              child: Container(
                color: widget.shell.cardBackground,
                child: Image.network(
                  resolved,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    color: widget.shell.detailBackground,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: widget.shell.hintColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
