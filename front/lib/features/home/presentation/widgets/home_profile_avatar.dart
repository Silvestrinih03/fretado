import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';

/// Uses the existing profile request; headers and navigation don't fetch separately.
class HomeProfileAvatar extends StatelessWidget {
  final int userId;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderRadius? borderRadius;

  const HomeProfileAvatar({
    super.key,
    required this.userId,
    this.size = 34,
    this.iconSize = 19,
    this.backgroundColor = FretColors.brandBlack,
    this.foregroundColor = FretColors.white,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final service = MyselfService();
    return ValueListenableBuilder<MyselfUserModel?>(
      valueListenable: service.currentProfile,
      builder: (context, profile, _) => FretAvatar(
        imageUrl: service.currentUserId == userId ? profile?.avatarUrl : null,
        size: size,
        iconSize: iconSize,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    );
  }
}
