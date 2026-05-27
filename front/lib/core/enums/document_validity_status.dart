import 'package:flutter/material.dart';

import '../../app/design_system/design_system.dart';

enum DocumentValidityStatusEnum {
  needsInformation,
  valid,
  expiringSoon,
  expired;

  Color get borderColor {
    return switch (this) {
      DocumentValidityStatusEnum.needsInformation =>
        FretColors.secondaryVariation500,
      DocumentValidityStatusEnum.valid => FretColors.success500,
      DocumentValidityStatusEnum.expiringSoon => FretColors.attention500,
      DocumentValidityStatusEnum.expired => FretColors.destructive500,
    };
  }

  Color get iconColor {
    return switch (this) {
      DocumentValidityStatusEnum.needsInformation =>
        FretColors.secondaryVariation700,
      DocumentValidityStatusEnum.valid => FretColors.success700,
      DocumentValidityStatusEnum.expiringSoon => FretColors.attention700,
      DocumentValidityStatusEnum.expired => FretColors.destructive700,
    };
  }

  Color get iconBackgroundColor {
    return switch (this) {
      DocumentValidityStatusEnum.needsInformation =>
        FretColors.secondaryVariation050,
      DocumentValidityStatusEnum.valid => FretColors.success050,
      DocumentValidityStatusEnum.expiringSoon => FretColors.attention050,
      DocumentValidityStatusEnum.expired => FretColors.destructive050,
    };
  }

  IconData get icon {
    return switch (this) {
      DocumentValidityStatusEnum.needsInformation =>
        Icons.edit_document,
      DocumentValidityStatusEnum.valid => Icons.remove_red_eye_sharp, // era check_circle_outline_rounded
      DocumentValidityStatusEnum.expiringSoon => Icons.error_outline_rounded,
      DocumentValidityStatusEnum.expired => Icons.warning_amber_rounded,
    };
  }
}
