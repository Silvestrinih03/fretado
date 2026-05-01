import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../data/models/change_password_model.dart';
import '../../data/models/update_user_model.dart';
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

  Future<MyselfUserModel> updateUser({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
    String? birthDate,
    String? phone,
  }) async {
    final String trimmedFirstName = firstName.trim();
    final String trimmedLastName = lastName.trim();
    final String trimmedEmail = email.trim();

    if (trimmedFirstName.isEmpty || trimmedLastName.isEmpty) {
      throw const ProfileControllerException(
        'Informe nome e sobrenome para salvar.',
      );
    }

    final bool validEmail = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(trimmedEmail);
    if (!validEmail) {
      throw const ProfileControllerException('Informe um email valido.');
    }

    final UpdateUserModel payload = UpdateUserModel(
      firstName: trimmedFirstName,
      lastName: trimmedLastName,
      email: trimmedEmail,
      birthDate: _normalizeBirthDate(birthDate),
      phone: _normalizePhone(phone),
    );

    return _repository.updateUser(userId: userId, payload: payload);
  }

  String? _normalizeBirthDate(String? birthDate) {
    final String raw = (birthDate ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }

    final RegExp isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final Match? isoMatch = isoPattern.firstMatch(raw);
    if (isoMatch != null) {
      _validateDate(
        year: isoMatch.group(1)!,
        month: isoMatch.group(2)!,
        day: isoMatch.group(3)!,
      );
      return raw;
    }

    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw const ProfileControllerException(
        'Informe a data de nascimento no formato DD/MM/AAAA.',
      );
    }

    final String day = digits.substring(0, 2);
    final String month = digits.substring(2, 4);
    final String year = digits.substring(4, 8);
    _validateDate(year: year, month: month, day: day);

    return '$year-$month-$day';
  }

  String? _normalizePhone(String? phone) {
    final String digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return '';
    }

    return digits;
  }

  void _validateDate({
    required String year,
    required String month,
    required String day,
  }) {
    final int? parsedYear = int.tryParse(year);
    final int? parsedMonth = int.tryParse(month);
    final int? parsedDay = int.tryParse(day);

    if (parsedYear == null || parsedMonth == null || parsedDay == null) {
      throw const ProfileControllerException(
        'Informe uma data de nascimento valida.',
      );
    }

    final DateTime parsedDate = DateTime(parsedYear, parsedMonth, parsedDay);
    final bool isSameDate =
        parsedDate.year == parsedYear &&
        parsedDate.month == parsedMonth &&
        parsedDate.day == parsedDay;

    if (!isSameDate) {
      throw const ProfileControllerException(
        'Informe uma data de nascimento valida.',
      );
    }
  }
}

class ProfileControllerException implements Exception {
  final String message;

  const ProfileControllerException(this.message);

  @override
  String toString() => 'ProfileControllerException: $message';
}
