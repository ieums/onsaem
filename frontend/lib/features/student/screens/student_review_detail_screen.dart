import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/models/lesson_review_message.dart';
import 'package:ieum/features/student/data/models/lesson_review_session.dart';
import 'package:ieum/features/student/providers/lesson_review_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentReviewDetailScreen extends ConsumerStatefulWidget {
  const StudentReviewDetailScreen({super.key, required this.session});

  final LessonReviewSession session;

  @override
  ConsumerState<StudentReviewDetailScreen> createState() =>
      _StudentReviewDetailScreenState();
}

class _StudentReviewDetailScreenState
    extends ConsumerState<StudentReviewDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _pdfLocalPath;
  bool _isPdfLoading = false;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(lessonReviewChatProvider.notifier)
          .init(widget.session.lessonId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo(String url) async {
  _videoPlayerController =
      VideoPlayerController.networkUrl(Uri.parse(url));
  await _videoPlayerController!.initialize();
  _chewieController = ChewieController(
    videoPlayerController: _videoPlayerController!,
    aspectRatio: 16 / 9,
    autoPlay: false,
    looping: false,
  );
  if (mounted) setState(() {});
}

  Future<void> _loadPdf(String url) async {
    if (_pdfLocalPath != null || _isPdfLoading) return;
    setState(() {
      _isPdfLoading = true;
      _pdfError = null;
    });
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/review_${widget.session.sessionId}.pdf');
      if (!file.existsSync()) {
        await Dio().download(url, file.path);
      }
      if (mounted) {
        setState(() {
          _pdfLocalPath = file.path;
          _isPdfLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pdfError = '요약 PDF를 불러오지 못했습니다.';
          _isPdfLoading = false;
        });
      }
    }
  }

  Future<void> _openPdfExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    await ref.read(lessonReviewChatProvider.notifier).sendMessage(text);
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

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final state = ref.watch(lessonReviewChatProvider);

    ref.listen<LessonReviewChatState>(lessonReviewChatProvider, (prev, next) {
      final res = next.resources;
      if (res == null) return;
      if (_videoPlayerController == null && res.hasVideo) {
        _initVideo(res.recordingUrl!);
      }
      if (_pdfLocalPath == null && !_isPdfLoading && res.hasPdf) {
        _loadPdf(res.pdfUrl!);
      }
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(shell, state),
            if (state.isInitializing)
              const LinearProgressIndicator(minHeight: 2, color: AppColors.studentPoint)
            else
              const SizedBox(height: 2),
            if (_chewieController != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Chewie(controller: _chewieController!),
              ),
            _buildTabBar(shell),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(child: _buildVideoSection(shell)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ReviewTabBarDelegate(
                        tabController: _tabController,
                        backgroundColor: pageBg,
                        indicatorColor: AppColors.studentInk,
                        labelColor: shell.titleColor,
                        unselectedColor: shell.hintColor,
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(shell),
                    _buildConceptTab(shell),
                    _buildMemoTab(shell),
                  ],
                ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatTab(shell, state),
                  _buildPdfTab(shell, state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ShellTheme shell, LessonReviewChatState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: shell.titleColor,
            ),
          ),
          Expanded(
            child: Text(
              state.session?.title ?? widget.session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: shell.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ShellTheme shell) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.studentPoint,
        indicatorWeight: 3,
        labelColor: shell.titleColor,
        unselectedLabelColor: shell.hintColor,
        labelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        dividerColor: Theme.of(context).dividerColor,
        tabs: const [
          Tab(text: '질문하기'),
          Tab(text: '요약 PDF'),
        ],
      ),
    );
  }

  // ── Chat tab ─────────────────────────────────────────────────────────────

  Widget _buildChatTab(ShellTheme shell, LessonReviewChatState state) {
    if (state.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.error!,
              style: TextStyle(color: shell.hintColor, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref
                  .read(lessonReviewChatProvider.notifier)
                  .init(widget.session.lessonId),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'AI 튜터에게 오늘 수업에 대해 질문해 보세요!',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: shell.hintColor, fontSize: 14),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: state.messages.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    message: state.messages[i],
                    shell: shell,
                  ),
                ),
        ),
        if (state.error != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              state.error!,
              style:
                  const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        _buildInputBar(shell, state),
      ],
    );
  }

  Widget _buildInputBar(ShellTheme shell, LessonReviewChatState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
              color: shell.cardBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              onSubmitted: (_) =>
                  state.isSending ? null : _sendMessage(),
              style:
                  TextStyle(fontSize: 15, color: shell.titleColor),
              decoration: InputDecoration(
                hintText: '질문을 입력하세요...',
                hintStyle: TextStyle(
                    color: shell.hintColor, fontSize: 14),
                filled: true,
                fillColor: isDark
                    ? shell.detailBackground
                    : shell.cardBackground,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                  borderSide: const BorderSide(
                      color: AppColors.studentPoint, width: 1.5),
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
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptSectionCard(
    ShellTheme shell,
    StudentReviewConceptSection section,
    int index,
  ) {
    return _buildConceptCard(
      shell: shell,
      leading: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.studentPoint.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Text(
          '$index',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.studentPoint,
          ),
        ),
      ),
      title: section.title,
      body: section.body,
      bullets: section.bullets,
      bulletColor: AppColors.studentPoint,
    );
  }

  Widget _buildConceptCard({
    required ShellTheme shell,
    required Widget leading,
    required String title,
    String? body,
    required List<String> bullets,
    required Color bulletColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder.withValues(alpha: 0.75)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: shell.titleColor,
                  ),
                ),
              ),
            ],
          ),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '잠시 후 다시 확인해 주세요.',
              style: TextStyle(
                  color: shell.hintColor.withValues(alpha: 0.7),
                  fontSize: 13),
            ),
          ],
        ),
      );
    }

  Widget _buildMemoTab(ShellTheme shell) {
    final memo = _currentMemo;
    final isEmpty = memo == null || memo.content.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: shell.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: shell.cardBorder.withValues(alpha: 0.7)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                      color: shell.hintColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '메모',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: shell.subtitleColor,
                      ),
                    ),
                    const Spacer(),
                    if (_memos.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: shell.detailBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MemoPageButton(
                              icon: Icons.chevron_left_rounded,
                              enabled: _memoPageIndex > 0,
                              onTap: () => setState(() {
                                _memoPageIndex--;
                                _isEditingMemo = false;
                              }),
                            ),
                            Text(
                              '${_memoPageIndex + 1}/${_memos.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: shell.subtitleColor,
                              ),
                            ),
                            _MemoPageButton(
                              icon: Icons.chevron_right_rounded,
                              enabled: _memoPageIndex < _memos.length - 1,
                              onTap: () => setState(() {
                                _memoPageIndex++;
                                _isEditingMemo = false;
                              }),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: GestureDetector(
                  onTap: !_isEditingMemo ? _startMemoEdit : null,
                  child: Container(
                    height: _memoBoxHeight,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? shell.detailBackground
                          : const Color(0xFFFAFBFE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isEditingMemo
                            ? shell.cardBorder
                            : shell.cardBorder.withValues(alpha: 0.55),
                      ),
                    ),
                    child: _isEditingMemo
                        ? Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: const InputDecorationTheme(
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: shell.titleColor,
                                selectionColor:
                                    shell.cardBorder.withValues(alpha: 0.45),
                                selectionHandleColor: shell.subtitleColor,
                              ),
                            ),
                            child: TextField(
                              controller: _memoEditController,
                              autofocus: true,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: shell.titleColor,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    '수업 내용, 헷갈린 점, 복습할 키워드를 적어 보세요',
                                hintStyle: TextStyle(
                                  color: shell.hintColor,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          )
                        : isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 36,
                                    color: shell.hintColor.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '탭해서 메모 작성',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: shell.hintColor,
                                    ),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Text(
                                  memo.content,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.65,
                                    color: shell.titleColor,
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
              if (memo != null &&
                  !_isEditingMemo &&
                  memo.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatDotDateTime(memo.updatedAt),
                      style: TextStyle(fontSize: 11, color: shell.hintColor),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: shell.cardBorder.withValues(alpha: 0.6)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: _isEditingMemo
                    ? Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _cancelMemoEdit,
                              child: Text(
                                '취소',
                                style: TextStyle(color: shell.hintColor),
                              ),
                            ),
                          ),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saveMemoEdit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.studentPoint,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('저장'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text(
                            _pdfError!,
                            style: TextStyle(
                                color: shell.hintColor, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _pdfError = null;
                                _pdfLocalPath = null;
                              });
                              _loadPdf(res.pdfUrl!);
                            },
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  : _pdfLocalPath != null
                      ? PDFView(
                          filePath: _pdfLocalPath!,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                        )
                      : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

// ── Message bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.shell});

  final LessonReviewMessage message;
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.studentPoint,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: shell.titleColor,
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
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
      child: const Icon(
        Icons.smart_toy_rounded,
        size: 16,
        color: AppColors.studentPoint,
      ),
    );
  }
}