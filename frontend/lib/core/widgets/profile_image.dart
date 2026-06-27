import 'package:flutter/material.dart';
import 'package:ieum/core/constants/api_constants.dart';

/// 프로필 이미지 역할(기본 이미지가 학생/강사로 다름).
enum ProfileRole { student, tutor }

/// 역할별 기본 프로필 이미지 자산 경로.
/// 실제 파일은 frontend/assets/images/ 에 넣는다(없어도 아래 위젯이 아이콘으로 폴백).
String defaultProfileAsset(ProfileRole role) => role == ProfileRole.tutor
    ? 'assets/images/default_tutor.png'
    : 'assets/images/default_student.png';

/// 역할별 기본 프로필 이미지. 자산 파일이 아직 없으면 사람 아이콘으로 폴백(빌드 안 깨짐).
class DefaultProfileImage extends StatelessWidget {
  const DefaultProfileImage({
    super.key,
    required this.role,
    this.size = 48,
    this.iconColor,
  });

  final ProfileRole role;
  final double size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      defaultProfileAsset(role),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Center(
        child: Icon(
          Icons.person,
          size: size * 0.55,
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }
}

/// 네트워크 프로필 이미지(있으면) → 없거나 로드 실패 시 역할별 기본 이미지로 폴백.
/// 호출부에서 ClipOval/CircleAvatar로 감싸 동그랗게 표시한다.
class ProfileImage extends StatelessWidget {
  const ProfileImage({
    super.key,
    required this.imageUrl,
    required this.role,
    this.size = 48,
    this.iconColor,
  });

  final String? imageUrl;
  final ProfileRole role;
  final double size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return DefaultProfileImage(role: role, size: size, iconColor: iconColor);
    }
    return Image.network(
      ApiConstants.resolveImageUrl(url),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          DefaultProfileImage(role: role, size: size, iconColor: iconColor),
    );
  }
}
