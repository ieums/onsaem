import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/lesson/presentation/lesson_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const EntryScreen(),
    ),
    GoRoute(
      path: '/lesson',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>;
        return LessonScreen(
          channelName: params['channelName'] as String,
          uid: params['uid'] as int,
          isTutor: params['isTutor'] as bool,
        );
      },
    ),
  ],
);

// ─── 입장 화면 ─────────────────────────────────────────────────────────────────

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _channelCtrl = TextEditingController();
  final _uidCtrl = TextEditingController(text: '1');
  bool _isTutor = true;

  @override
  void dispose() {
    _channelCtrl.dispose();
    _uidCtrl.dispose();
    super.dispose();
  }

  void _enter() {
    if (!_formKey.currentState!.validate()) return;
    final uid = int.tryParse(_uidCtrl.text.trim());
    if (uid == null) return;
    context.go('/lesson', extra: {
      'channelName': _channelCtrl.text.trim(),
      'uid': uid,
      'isTutor': _isTutor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('온샘'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '수업 입장',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _channelCtrl,
                  decoration: const InputDecoration(
                    labelText: '채널명',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '채널명을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _uidCtrl,
                  decoration: const InputDecoration(
                    labelText: 'UID (숫자)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || int.tryParse(v.trim()) == null)
                          ? '숫자를 입력해주세요'
                          : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('역할:',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('튜터(강사)')),
                        ButtonSegment(value: false, label: Text('학생')),
                      ],
                      selected: {_isTutor},
                      onSelectionChanged: (s) =>
                          setState(() => _isTutor = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _enter,
                  child: const Text('수업 입장',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
