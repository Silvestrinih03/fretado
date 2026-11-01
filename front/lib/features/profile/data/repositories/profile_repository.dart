import '../../../../core/services/myself/models/myself_user_model.dart';
import '../models/change_password_model.dart';
import '../models/update_user_model.dart';
import '../models/avatar_image.dart';

abstract class ProfileRepository {
  Future<MyselfUserModel> uploadAvatar({
    required int userId,
    required AvatarImage image,
  });
  Future<MyselfUserModel> removeAvatar({required int userId});

  Future<void> changePassword({
    required int userId,
    required ChangePasswordModel payload,
  });

  Future<MyselfUserModel> updateUser({
    required int userId,
    required UpdateUserModel payload,
  });
}
