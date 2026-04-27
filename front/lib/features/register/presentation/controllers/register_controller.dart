import 'package:flutter/foundation.dart';

import '../../data/models/register_user_model.dart';
import '../../data/repositories/register_repository.dart';

class RegisterController extends ChangeNotifier {
  final RegisterRepository _registerRepository;

  RegisterController(this._registerRepository);

  bool _isLoading = false;
  String? _errorMessage;
  RegisterUserModel? _registeredUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RegisterUserModel? get registeredUser => _registeredUser;

  bool validateStepTwo({
    required String cpf,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final String normalizedCpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (normalizedCpf.length < 11) {
      _errorMessage = 'Informe um CPF válido.';
      notifyListeners();
      return false;
    }

    final String trimmedEmail = email.trim();
    final bool validEmail = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(trimmedEmail);
    if (!validEmail) {
      _errorMessage = 'Informe um email válido.';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      _errorMessage = 'A senha deve ter no mínimo 8 caracteres.';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'A confirmação de senha não confere.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String cpf,
    required String email,
    required String password,
    required int userTypeId,
    required String firstName,
    required String lastName,
    String? birthDate,
    String? phone,
  }) async {
    final String trimmedFirstName = firstName.trim();
    final String trimmedLastName = lastName.trim();

    if (trimmedFirstName.isEmpty || trimmedLastName.isEmpty) {
      _errorMessage = 'Informe nome e sobrenome para continuar.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final RegisterUserModel user = await _registerRepository.register(
        cpf: cpf,
        email: email,
        password: password,
        userTypeId: userTypeId,
        firstName: trimmedFirstName,
        lastName: trimmedLastName,
        birthDate: _normalizeBirthDate(birthDate),
        phone: _normalizeOptional(phone),
      );

      _registeredUser = user;
      return true;
    } on RegisterRepositoryException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível concluir o cadastro agora.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String? _normalizeOptional(String? value) {
    final String cleaned = (value ?? '').trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  String? _normalizeBirthDate(String? birthDate) {
    final String raw = (birthDate ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }

    final RegExp slashPattern = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$');
    final Match? slashMatch = slashPattern.firstMatch(raw);
    if (slashMatch != null) {
      final String day = slashMatch.group(1)!;
      final String month = slashMatch.group(2)!;
      final String year = slashMatch.group(3)!;
      return '$year-$month-$day';
    }

    final RegExp isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoPattern.hasMatch(raw)) {
      return raw;
    }

    return null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
