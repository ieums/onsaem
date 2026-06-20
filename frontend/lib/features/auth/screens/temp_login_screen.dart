import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_paths.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_button.dart';

class TempLoginScreen extends ConsumerStatefulWidget {
  const TempLoginScreen({super.key});

  @override
  ConsumerState<TempLoginScreen> createState() => _TempLoginScreenState();
}

class _TempLoginScreenState extends ConsumerState<TempLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController(text: '1');
  bool _isTutor = true;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  void _enter() {
    if (!_formKey.currentState!.validate()) return;
    final id = int.tryParse(_idCtrl.text.trim());
    if (id == null) return;
    ref.read(currentUserProvider.notifier).state =
        UserSession(id: id, isTutor: _isTutor);
    context.go(_isTutor ? RoutePaths.tutorHome : RoutePaths.studentHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  '온샘',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '임시 로그인',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const Text(
                  '역할 선택',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('강사')),
                    ButtonSegment(value: false, label: Text('학생')),
                  ],
                  selected: {_isTutor},
                  onSelectionChanged: (s) =>
                      setState(() => _isTutor = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? AppColors.primaryBlue
                          : null;
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ID 입력',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _idCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '숫자 ID를 입력하세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || int.tryParse(v.trim()) == null)
                          ? '숫자를 입력해주세요'
                          : null,
                ),
                const SizedBox(height: 32),
                CommonButton(label: '입장', onPressed: _enter),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
