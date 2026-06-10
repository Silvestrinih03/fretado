import 'package:flutter/foundation.dart';

import '../../data/models/register_user_model.dart';
import '../../data/repositories/register_repository.dart';

const String _weakPasswordMessage =
    'A senha deve ter no mínimo 8 caracteres, 1 maiúscula, 1 minúscula, 1 número e 1 caractere especial.';

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
    if (!_isValidCpf(normalizedCpf)) {
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

    if (!_isStrongPassword(password)) {
      _errorMessage = _weakPasswordMessage;
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
    final String normalizedCpf = _normalizeCpf(cpf);
    final String trimmedFirstName = firstName.trim();
    final String trimmedLastName = lastName.trim();

    if (!_isValidCpf(normalizedCpf)) {
      _errorMessage = 'Informe um CPF válido.';
      notifyListeners();
      return false;
    }

    if (!_isStrongPassword(password)) {
      _errorMessage = _weakPasswordMessage;
      notifyListeners();
      return false;
    }

    if (trimmedFirstName.isEmpty || trimmedLastName.isEmpty) {
      _errorMessage = 'Informe nome e sobrenome para continuar.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final RegisterUserModel user = await _registerRepository.register(
        cpf: normalizedCpf,
        email: email,
        password: password,
        userTypeId: userTypeId,
        firstName: trimmedFirstName,
        lastName: trimmedLastName,
        birthDate: _normalizeBirthDate(birthDate),
        phone: _normalizePhone(phone),
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

  String _normalizeCpf(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  bool _isValidCpf(String cpf) {
    if (cpf.length != 11 || RegExp(r'^(\d)\1*$').hasMatch(cpf)) {
      return false;
    }

    final int firstDigit = _calculateCpfDigit(cpf.substring(0, 9), 10);
    final int secondDigit = _calculateCpfDigit(cpf.substring(0, 10), 11);

    return cpf.endsWith('$firstDigit$secondDigit');
  }

  int _calculateCpfDigit(String digits, int startWeight) {
    var total = 0;
    for (var index = 0; index < digits.length; index += 1) {
      total += int.parse(digits[index]) * (startWeight - index);
    }

    final int remainder = (total * 10) % 11;
    return remainder == 10 ? 0 : remainder;
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9\s]').hasMatch(password);
  }

  String? _normalizePhone(String? value) {
    final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return null;
    }

    return digits;
  }

  String? _normalizeBirthDate(String? birthDate) {
    final String raw = (birthDate ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }

    final RegExp isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoPattern.hasMatch(raw)) {
      return raw;
    }

    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      return null;
    }

    final String day = digits.substring(0, 2);
    final String month = digits.substring(2, 4);
    final String year = digits.substring(4, 8);
    return '$year-$month-$day';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
