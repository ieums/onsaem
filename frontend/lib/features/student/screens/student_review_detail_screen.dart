import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/storage/token_storage.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/data/models/lesson_review_message.dart';
import 'package:ieum/features/student/providers/lesson_review_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentReviewDetailScreen extends ConsumerStatefulWidget {
  const StudentReviewDetailScreen({
    super.key,
    required this.lessonId,
    required this.title,
  });

  /// 복습 대상 강의. 세션은 진입 시 init(lessonId)이 없으면 만들고 있으면 재사용한다.
  final int lessonId;
  final String title;

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
          .init(widget.lessonId);
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
  // 녹음은 인증+소유권 체크 엔드포인트(local)라 JWT를 함께 보낸다.
  // (prod의 presigned S3 URL은 헤더가 있어도 무시되므로 안전)
  final token = await tokenStorage.readAccessToken();
  _videoPlayerController = VideoPlayerController.networkUrl(
    Uri.parse(url),
    httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : const {},
  );
  await _videoPlayerController!.initialize();
  _chewieController = ChewieController(
    videoPlayerController: _videoPlayerController!,
    aspectRatio: 16 / 9,
    autoPlay: false,
    looping: false,
  );
  if (mounted) setState(() {});
}

  Future<void> _loadPdf(String rawUrl) async {
    if (_pdfLocalPath != null || _isPdfLoading) return;
    // PDF는 상대경로(/uploads/...)로 와서 origin을 붙여 절대화해야 다운로드된다.
    final url = ApiConstants.resolveImageUrl(rawUrl);
    setState(() {
      _isPdfLoading = true;
      _pdfError = null;
    });
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/review_${widget.lessonId}.pdf');
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

  Future<void> _openPdfExternal(String rawUrl) async {
    final uri = Uri.parse(ApiConstants.resolveImageUrl(rawUrl));
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
        // 로컬은 '/uploads/...' 상대경로, prod는 S3 절대 URL → resolve로 통일
        _initVideo(ApiConstants.resolveImageUrl(res.recordingUrl!));
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
              state.session?.title ?? widget.title,
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
                  .init(widget.lessonId),
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

  // ── PDF tab ──────────────────────────────────────────────────────────────

  Widget _buildPdfTab(ShellTheme shell, LessonReviewChatState state) {
    if (state.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final res = state.resources;
    if (res == null || !res.hasPdf) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: shell.hintColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'AI가 강의 요약 PDF를 준비 중입니다.',
              style: TextStyle(color: shell.hintColor, fontSize: 14),
            ),
            const SizedBox(height: 4),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openPdfExternal(res.pdfUrl!),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('다운로드'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.studentPoint,
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isPdfLoading
              ? const Center(child: CircularProgressIndicator())
              : _pdfError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
          if (!isUser) ...[
            _AiAvatar(isDark: isDark),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.studentPoint
                    : (isDark
                        ? shell.detailBackground
                        : shell.cardBackground),
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
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: isUser ? Colors.white : shell.titleColor,
                ),
              ),
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