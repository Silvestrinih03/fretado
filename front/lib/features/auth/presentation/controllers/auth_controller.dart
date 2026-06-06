import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthController(this._authRepository);

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  Future<bool> login({required String email, required String password}) async {
    final String trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || password.isEmpty) {
      _errorMessage = 'Preencha email e senha para continuar.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final UserModel user = await _authRepository.login(
        email: trimmedEmail,
        password: password,
      );

      _currentUser = user;
      return true;
    } on AuthRepositoryException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível realizar login agora.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    final String trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      _errorMessage = 'Informe seu email para continuar.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.forgotPassword(email: trimmedEmail);
      return true;
    } on AuthRepositoryException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Nao foi possivel enviar o email de recuperacao agora.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final String trimmedToken = token.trim();

    if (trimmedToken.isEmpty) {
      _errorMessage = 'Link de recuperacao invalido.';
      notifyListeners();
      return false;
    }

    final String? passwordError = _validateNewPassword(
      newPassword,
      confirmPassword,
    );
    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _authRepository.resetPassword(
        token: trimmedToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } on AuthRepositoryException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Nao foi possivel redefinir sua senha agora.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String? _validateNewPassword(String password, String confirmation) {
    if (password.isEmpty || confirmation.isEmpty) {
      return 'Informe e confirme a nova senha.';
    }

    if (password != confirmation) {
      return 'A nova senha e a confirmacao nao conferem.';
    }

    if (password.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'A senha deve ter pelo menos uma letra maiuscula.';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'A senha deve ter pelo menos uma letra minuscula.';
    }

    if (!RegExp(r'\d').hasMatch(password)) {
      return 'A senha deve ter pelo menos um numero.';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'A senha deve ter pelo menos um caractere especial.';
    }

    return null;
  }
}
