import 'package:flutter/material.dart';

/// OCR 분석 중 보여주는 "걷는/뛰는" 마스코트 애니메이션.
///
/// 두 장의 PNG 프레임(ocr_walk_1/2.png)을 번갈아 보여주며 위아래로 통통 튀게 한다.
/// GIF 대신 PNG 2프레임을 쓰는 이유: 배경 제거(투명) 시 PNG는 부드러운 알파를 유지하지만
/// GIF는 투명도가 1비트라 가장자리가 지저분해진다.
///
/// 프레임 파일이 아직 없어도 빌드가 깨지지 않게 작은 스피너로 폴백한다.
class WalkingMascot extends StatefulWidget {
  const WalkingMascot({
    super.key,
    this.size = 88,
    this.frameDuration = const Duration(milliseconds: 480),
  });

  /// 마스코트 높이(px).
  final double size;

  /// 프레임 한 장을 유지하는 시간(두 장 = 한 걸음 사이클).
  final Duration frameDuration;

  @override
  State<WalkingMascot> createState() => _WalkingMascotState();
}

class _WalkingMascotState extends State<WalkingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _frames = [
    'assets/images/ocr_walk_1.png',
    'assets/images/ocr_walk_2.png',
  ];

  @override
  void initState() {
    super.initState();
    // 한 사이클 = 두 프레임. 각 프레임 구간마다 한 번씩 위로 통통 튄다.
    _c = AnimationController(
      vsync: this,
      duration: widget.frameDuration * 2,
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0→1→0 형태의 점프 아치(프레임 구간 내). easeInOut으로 부드럽게.
  double _arch(double x) =>
      Curves.easeInOut.transform(1 - (2 * x - 1).abs());

  @override
  Widget build(BuildContext context) {
    // 두 프레임을 미리 만들어 둘 다 트리에 유지(IndexedStack) → 전환 시 재디코드/깜빡임 없음.
    // 색 필터·투명도 변경 일절 없음(두 이미지를 그대로 보여줌).
    final frames = [_frameImage(0), _frameImage(1)];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1
        final frame = t < 0.5 ? 0 : 1;
        final local = (t % 0.5) / 0.5; // 현재 프레임 구간 진행도 0..1
        final bob = -(widget.size * 0.08) * _arch(local); // 위로 살짝(차분하게)
        return Transform.translate(
          offset: Offset(0, bob),
          child: IndexedStack(
            alignment: Alignment.center,
            index: frame,
            children: frames,
          ),
        );
      },
    );
  }

  Widget _frameImage(int i) {
    return Image.asset(
      _frames[i],
      height: widget.size,
      fit: BoxFit.contain,
      // 이미지가 아직 없을 때도 스피너 대신 정적 아이콘으로(동글동글 방지).
      errorBuilder: (_, _, _) => SizedBox(
        height: widget.size,
        width: widget.size,
        child: Icon(
          Icons.image_outlined,
          size: widget.size * 0.5,
          color: const Color(0x33000000),
        ),
      ),
    );
  }
}
