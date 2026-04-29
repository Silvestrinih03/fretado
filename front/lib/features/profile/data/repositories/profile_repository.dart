import '../models/change_password_model.dart';

abstract class ProfileRepository {
  Future<void> changePassword({
    required int userId,
    required ChangePasswordModel payload,
  });
}
