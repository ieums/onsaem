import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/widgets/profile_image.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/tutor_profile_repository.dart';
import 'package:ieum/features/student/models/tutor_profile_detail.dart';
import 'package:ieum/features/student/widgets/student_action_button_style.dart';
import 'package:ieum/features/tutor/widgets/review_summary.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

class StudentTutorProfileScreen extends ConsumerStatefulWidget {
  const StudentTutorProfileScreen({
    super.key,
    required this.tutorId,
  });

  final String tutorId;

  @override
  ConsumerState<StudentTutorProfileScreen> createState() =>
      _StudentTutorProfileScreenState();
}

class _StudentTutorProfileScreenState
    extends ConsumerState<StudentTutorProfileScreen> {
  int _tabIndex = 0;

  void _selectTutor() {
    ref.read(studentMatchingSessionProvider.notifier).selectTutor(widget.tutorId);
    context.pop();
  }

  ThemeData _buildTheme(bool isDark) {
    final base = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.studentScaffoldLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final theme = _buildTheme(isDark);
    final tutorIdInt = int.tryParse(widget.tutorId);

    final session = ref.watch(studentMatchingSessionProvider);
    final applicant = session?.applicants
        .where((a) => a.tutorId.toString() == widget.tutorId)
        .firstOrNull;
    final isOnline = applicant?.isOnline ?? false;
    final canSelect = session != null &&
        session.status == StudentMatchingSessionStatus.selectingTutor &&
        applicant != null;

    if (tutorIdInt == null) {
      return Theme(
        data: theme,
        child: Scaffold(
          appBar: StudentFlowAppBar(title: '강사 프로필'),
          body: const Center(child: Text('잘못된 강사 ID입니다.')),
        ),
      );
    }

    final profileAsync = ref.watch(tutorProfileProvider(tutorIdInt));

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          return profileAsync.when(
            loading: () => Scaffold(
              appBar: StudentFlowAppBar(title: '강사 프로필'),
              body: const Center(
                child: CircularProgressIndicator(color: AppColors.studentPoint),
              ),
            ),
            error: (_, _) => Scaffold(
              appBar: StudentFlowAppBar(title: '강사 프로필'),
              body: Center(
                child: Text(
                  '강사 정보를 불러오지 못했어요.',
                  style: TextStyle(color: shell.hintColor, fontSize: 14),
                ),
              ),
            ),
            data: (profile) => _buildContent(
              context: context,
              shell: shell,
              theme: theme,
              profile: profile,
              isOnline: isOnline,
              canSelect: canSelect,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required ShellTheme shell,
    required ThemeData theme,
    required TutorProfileDetail profile,
    required bool isOnline,
    required bool canSelect,
  }) {
    final pageBg = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: StudentFlowAppBar(title: '강사 프로필'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                _buildProfileHeader(shell, profile, isOnline, canSelect),
                const SizedBox(height: 14),
                _buildMetrics(shell, profile),
                const SizedBox(height: 16),
                _buildSegmentTabs(shell, profile.reviewCount),
                const SizedBox(height: 16),
                if (_tabIndex == 0)
                  _buildIntroTab(shell, profile)
                else
                  _buildReviewsTab(shell, profile),
              ],
            ),
          ),
          // 매칭 선택 흐름으로 들어왔을 때만 '선택하기' 노출.
          // 리뷰 내역 등에서 프로필만 보러 들어오면(canSelect=false) 버튼 영역 자체를 숨긴다.
          if (canSelect) ...[
            Divider(height: 1, thickness: 1, color: shell.cardBorder),
            ColoredBox(
              color: pageBg,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _selectTutor,
                    // 통일 스타일: 테두리 특징색 + 흰/다크 배경 + 검정/특징색 글씨.
                    style: studentOutlinedButtonStyle(isDark, radius: 14),
                    child: const Text(
                      '선택하기',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    ShellTheme shell,
    TutorProfileDetail profile,
    bool isOnline,
    bool showOnline, // 매칭 선택 흐름일 때만 온/오프라인 배지 노출(리뷰 내역에선 무의미)
  ) {
    final schoolText = [
      if (profile.school?.isNotEmpty ?? false) profile.school!,
      if (profile.major?.isNotEmpty ?? false) profile.major!,
    ].join(' ');
    final hasSchool = schoolText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(shell, profile),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: shell.titleColor,
                        ),
                      ),
                    ),
                    if (showOnline) ...[
                      const SizedBox(width: 8),
                      _OnlineStatusBadge(isOnline: isOnline),
                    ],
                  ],
                ),
                if (hasSchool) ...[
                  const SizedBox(height: 4),
                  Text(
                    schoolText,
                    style: TextStyle(
                      fontSize: 14,
                      color: shell.subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ShellTheme shell, TutorProfileDetail profile) {
    const size = 64.0;
    // 강사 프로필이므로 강사 기본 프로필 이미지로 폴백(에셋 없으면 위젯이 아이콘으로 폴백).
    return ClipOval(
      child: ProfileImage(
        imageUrl: profile.profileImageUrl,
        role: ProfileRole.tutor,
        size: size,
        iconColor: shell.hintColor,
      ),
    );
  }

  Widget _buildMetrics(ShellTheme shell, TutorProfileDetail profile) {
    final ratingText = profile.ratingAvg != null
        ? profile.ratingAvg!.toStringAsFixed(1)
        : '-';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudentTutorMetricChip(
            icon: Icons.star_rounded,
            iconColor: AppColors.reviewHighlight,
            label: '평점',
            value: ratingText,
          ),
          const SizedBox(width: 8),
          StudentTutorMetricChip(
            label: '수업',
            value: '${profile.lessonCount}회',
          ),
          const SizedBox(width: 8),
          StudentTutorMetricChip(
            label: '리뷰',
            value: '${profile.reviewCount}개',
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTabs(ShellTheme shell, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: shell.detailBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _SegmentTab(
            label: '소개',
            selected: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          _SegmentTab(
            label: '리뷰 $reviewCount',
            selected: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroTab(ShellTheme shell, TutorProfileDetail profile) {
    final hasBio = profile.bio?.trim().isNotEmpty ?? false;
    final hasSubjects = profile.subjects.isNotEmpty;

    if (!hasBio && !hasSubjects) {
      return _emptyCard(shell, '소개 정보가 없어요.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBio)
          _ContentCard(
            title: '소개',
            child: Text(
              profile.bio!.trim(),
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: shell.subtitleColor,
              ),
            ),
          ),
        if (hasBio && hasSubjects) const SizedBox(height: 12),
        if (hasSubjects)
          _ContentCard(
            title: '담당 과목',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final subject in profile.subjects)
                  TutorSubjectBadge(subject: _localizeSubject(subject)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsTab(ShellTheme shell, TutorProfileDetail profile) {
    if (profile.reviews.isEmpty) {
      return _emptyCard(shell, '아직 리뷰가 없어요.');
    }
    return Column(
      children: [
        // 상단 별점 요약(평균 + 점수별 분포) — 받은 리뷰 화면과 동일.
        ReviewSummary(shell: shell, profile: profile),
        const SizedBox(height: 8),
        Divider(color: shell.cardBorder.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        for (final review in profile.reviews) ...[
          _ReviewCard(shell: shell, review: review),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _localizeSubject(String subject) {
    const map = {
      'MATH': '수학',
      'KOREAN': '국어',
      'ENGLISH': '영어',
      'SCIENCE': '과학',
      'SOCIAL': '사회',
    };
    return map[subject] ?? subject;
  }

  Widget _emptyCard(ShellTheme shell, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: shell.hintColor),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Private helper widgets
// ────────────────────────────────────────────────────────────

class _OnlineStatusBadge extends StatelessWidget {
  const _OnlineStatusBadge({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.studentPoint.withValues(alpha: 0.25)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isOnline
              ? AppColors.studentPoint.withValues(alpha: 0.8)
              : Colors.grey.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        isOnline ? '온라인' : '오프라인',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOnline ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    return Expanded(
      child: Material(
        color: selected ? shell.cardBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? shell.titleColor : shell.hintColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: shell.titleColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.shell, required this.review});

  final ShellTheme shell;
  final TutorReviewItem review;

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.studentName ?? '학생',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: shell.titleColor,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(fontSize: 12, color: shell.hintColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 15,
                  color: AppColors.reviewHighlight,
                ),
            ],
          ),
          if (review.comment?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: shell.subtitleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
