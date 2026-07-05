import 'package:flutter/material.dart';
import 'package:ieum/core/widgets/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/models/ai_tutor_message.dart';
import 'package:ieum/features/student/providers/ai_tutor_provider.dart';
import 'package:ieum/features/student/providers/payment_provider.dart';
import 'package:ieum/features/student/utils/coin_shortage.dart';
import 'package:ieum/features/student/widgets/student_problem_image_viewer.dart';
import 'package:ieum/core/constants/api_constants.dart';

class StudentAiTutorScreen extends ConsumerStatefulWidget {
  const StudentAiTutorScreen({
    super.key,
    required this.problemId,
    this.problemSummary,
  });

  final int problemId;
  final String? problemSummary;

  @override
  ConsumerState<StudentAiTutorScreen> createState() =>
      _StudentAiTutorScreenState();
}

class _StudentAiTutorScreenState extends ConsumerState<StudentAiTutorScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _problemExpanded = false;
  int _problemImagePage = 0; // 확장된 문제 이미지 페이저 현재 페이지

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiTutorChatProvider.notifier).init(widget.problemId);
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    await ref.read(aiTutorChatProvider.notifier).sendMessage(text);
    if (!mounted) return;
    // 질문당 3코인(비구독자)이 즉시 차감됐으니 잔액 표시를 갱신.
    ref.invalidate(coinBalanceProvider);
    // 비구독자 잔액 부족(질문당 3코인) → 충전 안내 후 재시도.
    final err = ref.read(aiTutorChatProvider).error;
    if (isCoinShortageMessage(err)) {
      final charged = await promptRechargeAndReturn(context,
          theme: ref.read(shellDarkModeProvider)
              ? AppTheme.shellDark
              : AppTheme.shellLight);
      if (charged && mounted) {
        await ref.read(aiTutorChatProvider.notifier).sendMessage(text);
        if (!mounted) return;
        ref.invalidate(coinBalanceProvider);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmClose(BuildContext context) async {
    final ok = await showConfirmDialog(
      context: context,
      title: '대화 종료',
      message: '이 AI 튜터 대화를 종료할까요?\n종료하면 더 이상 질문할 수 없어요.',
      cancelText: '취소',
      confirmText: '종료',
      isDanger: true,
    );
    if (!ok) return;
    final closed = await ref.read(aiTutorChatProvider.notifier).close();
    if (closed && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme:
          baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.studentScaffoldLight,
    );

    final state = ref.watch(aiTutorChatProvider);

    ref.listen<AiTutorChatState>(aiTutorChatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    size: 20, color: shell.titleColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'AI 튜터',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: shell.titleColor,
                ),
              ),
              actions: [
                if (state.session != null && !state.session!.status.isClosed)
                  TextButton(
                    onPressed: () => _confirmClose(context),
                    child: const Text(
                      '종료',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (state.isInitializing)
                    const LinearProgressIndicator(
                        minHeight: 2, color: AppColors.studentPoint),
                  _buildProblemBanner(shell, state),
                  Expanded(child: _buildBody(shell, state)),
                  if (state.error != null && state.messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  _buildInputBar(shell, state),
                  _buildAiNotice(shell),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ShellTheme shell, AiTutorChatState state) {
    if (state.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!,
                style: TextStyle(color: shell.hintColor, fontSize: 14)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref
                  .read(aiTutorChatProvider.notifier)
                  .init(widget.problemId),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '이 문제에 대해 궁금한 점을 AI 튜터에게 물어보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: shell.hintColor, fontSize: 14, height: 1.5),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: state.messages.length,
      itemBuilder: (_, i) =>
          _MessageBubble(message: state.messages[i], shell: shell),
    );
  }
    Widget _buildProblemBanner(ShellTheme shell, AiTutorChatState state) {
    final problem = state.problem;
    final summary = (problem?.summary?.trim().isNotEmpty ?? false)
        ? problem!.summary!.trim()
        : (widget.problemSummary?.trim() ?? '');
    final images = problem?.imageUrls ?? const <String>[];
    // 보여줄 게 없으면 배너 숨김
    if (images.isEmpty && summary.isEmpty) return const SizedBox.shrink();

    final firstImageUrl =
        images.isNotEmpty ? ApiConstants.resolveImageUrl(images.first) : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: shell.cardBackground,
        border: Border(
          bottom: BorderSide(color: shell.cardBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _problemExpanded = !_problemExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  if (firstImageUrl != null)
                    GestureDetector(
                      onTap: () => _showImageViewer(images),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          firstImageUrl,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _bannerThumbFallback(shell),
                        ),
                      ),
                    )
                  else
                    _bannerThumbFallback(shell),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '문제',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.studentPoint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary.isNotEmpty
                              ? summary
                              : '이미지를 눌러 문제를 확인하세요',
                          // 접힘 상태도 2줄까지 보여 제목이 한 줄로 잘리지 않게.
                          maxLines: _problemExpanded ? 8 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: shell.titleColor,
                            height: 1.4,
                          ),
                        ),
                        if (!_problemExpanded && summary.length > 30)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '탭하여 전체 보기',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.studentPoint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _problemExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: shell.hintColor,
                  ),
                ],
              ),
            ),
          ),
          if (_problemExpanded && images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        // 여러 장이면 좌우로 넘겨 본다(눌러서 확대도 그대로).
                        PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (i) =>
                              setState(() => _problemImagePage = i),
                          itemBuilder: (_, i) {
                            final url =
                                ApiConstants.resolveImageUrl(images[i]);
                            return GestureDetector(
                              onTap: () => _showImageViewer(images),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  color: shell.cardBackground,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (images.length > 1)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_problemImagePage + 1}/${images.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (images.length > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < images.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _problemImagePage ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _problemImagePage
                                  ? AppColors.studentPoint
                                  : shell.cardBorder,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bannerThumbFallback(ShellTheme shell) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: shell.cardBorder.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_outlined, size: 22, color: shell.hintColor),
    );
  }

  void _showImageViewer(List<String> imageUrls) {
    if (imageUrls.isEmpty) return;
    // 다른 화면과 동일한 좌우 스와이프 갤러리(확대/페이지 카운터 포함).
    showStudentProblemImageGalleryUrls(
      context,
      imageUrls: [for (final u in imageUrls) ApiConstants.resolveImageUrl(u)],
    );
  }

  // AI 생성물 표시(인공지능기본법). 답변이 부정확할 수 있음을 항상 고지.
  Widget _buildAiNotice(ShellTheme shell) {
    return Container(
      width: double.infinity,
      color: shell.scaffoldBackground,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        'AI 튜터는 실수할 수 있습니다. 응답을 다시 한 번 확인해 주세요.',
        textAlign: TextAlign.center,
        style: TextStyle(color: shell.hintColor, fontSize: 11, height: 1.3),
      ),
    );
  }

  Widget _buildInputBar(ShellTheme shell, AiTutorChatState state) {
    // 주의: 이 메서드는 build의 Theme 오버라이드 '바깥'인 State.context를 쓰므로
    // Theme.of(context)를 쓰면 라이트 테마가 잡혀 입력창만 흰색이 된다.
    // 색은 항상 themed shell / shellDarkModeProvider 기준으로 가져온다.
    final isDark = ref.read(shellDarkModeProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: shell.scaffoldBackground,
        border: Border(
          top: BorderSide(color: shell.cardBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              onSubmitted: (_) => state.isSending ? null : _sendMessage(),
              style: TextStyle(fontSize: 15, color: shell.titleColor),
              decoration: InputDecoration(
                hintText: '질문을 입력하세요...',
                hintStyle: TextStyle(color: shell.hintColor, fontSize: 14),
                filled: true,
                fillColor:
                    isDark ? shell.detailBackground : shell.cardBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: shell.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: shell.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.studentPoint, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: state.isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: state.isSending
                    ? AppColors.studentPoint.withValues(alpha: 0.4)
                    : AppColors.studentPoint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: state.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.shell});

  final AiTutorMessage message;
  final ShellTheme shell;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _AiAvatar(isDark: isDark),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.studentPoint
                    : (isDark ? shell.detailBackground : shell.cardBackground),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: shell.cardBorder.withValues(alpha: 0.6)),
              ),
              child: Text(
                _stripMarkdown(message.content),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  // 유저 버블이 연두(studentPoint)라 글씨는 검정으로.
                  color: isUser ? Colors.black : shell.titleColor,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _stripMarkdown(String input) {
    var t = input;
    t = t.replaceAll(RegExp(r'```[a-zA-Z]*\n?'), '');
    t = t.replaceAll('`', '');
    t = t.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
    t = t.replaceAllMapped(RegExp(r'\*\*\*(.+?)\*\*\*'), (m) => m[1]!);
    t = t.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!);
    t = t.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!);
    t = t.replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ');
    return t.trim();
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.studentPoint.withValues(alpha: 0.2)
            : AppColors.studentPoint.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.smart_toy_rounded,
          size: 16, color: AppColors.studentPoint),
    );
  }
}