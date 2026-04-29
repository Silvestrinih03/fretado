import '../../data/models/change_password_model.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileController {
  final ProfileRepository _repository;

  const ProfileController(this._repository);

  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final ChangePasswordModel payload = ChangePasswordModel(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    await _repository.changePassword(userId: userId, payload: payload);
  }
}
