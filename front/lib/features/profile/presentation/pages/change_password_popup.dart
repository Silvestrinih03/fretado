import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/profile_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../controllers/profile_controller.dart';

class ChangePasswordPopup extends StatefulWidget {
  const ChangePasswordPopup({super.key});

  @override
  State<ChangePasswordPopup> createState() => _ChangePasswordPopupState();
}

class _ChangePasswordPopupState extends State<ChangePasswordPopup> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  HttpService? _httpService;
  String? _errorMessage;
  bool _isLoading = false;

  ProfileController get _profileController {
    final HttpService httpService = _httpService ??= HttpService();
    final ProfileDatasource datasource = ProfileDatasource(httpService);
    final ProfileRepositoryImpl repository = ProfileRepositoryImpl(datasource);
    return ProfileController(repository);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _httpService?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    final String? validationMessage = _validatePasswords(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (validationMessage != null) {
      setState(() => _errorMessage = validationMessage);
      return;
    }

    final int? userId = MyselfService().currentUserId;
    if (userId == null) {
      setState(() {
        _errorMessage = 'Não foi possível identificar o usuário.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _profileController.changePassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!mounted) {
        return;
      }

      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _readErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: FretColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Alteração de senha',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: FretColors.loginFooterLink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Digite a sua senha atual e a nova senha para alterar sua senha de acesso.',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: FretColors.neutral500,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            _PasswordPopupField(
              controller: _currentPasswordController,
              hintText: 'Senha atual.',
            ),
            const SizedBox(height: 30),
            _PasswordPopupField(
              controller: _newPasswordController,
              hintText: 'Digite a nova senha.',
            ),
            const SizedBox(height: 14),
            _PasswordPopupField(
              controller: _confirmPasswordController,
              hintText: 'Confirme a nova senha.',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: FretColors.destructive600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 190,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF070873),
                    foregroundColor: FretColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _isLoading ? 'Salvando...' : 'Salvar',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _validatePasswords({
  required String currentPassword,
  required String newPassword,
  required String confirmPassword,
}) {
  if (currentPassword.isEmpty ||
      newPassword.isEmpty ||
      confirmPassword.isEmpty) {
    return 'Preencha todos os campos.';
  }

  if (currentPassword.length < 8 ||
      newPassword.length < 8 ||
      confirmPassword.length < 8) {
    return 'As senhas devem ter pelo menos 8 caracteres.';
  }

  if (newPassword != confirmPassword) {
    return 'A nova senha e a confirmação não conferem.';
  }

  if (currentPassword == newPassword) {
    return 'A nova senha deve ser diferente da senha atual.';
  }

  return null;
}

String _readErrorMessage(Object error) {
  final String message = error.toString();
  final int separatorIndex = message.indexOf(': ');

  if (separatorIndex == -1) {
    return message;
  }

  return message.substring(separatorIndex + 2);
}

class _PasswordPopupField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _PasswordPopupField({
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(
        color: FretColors.neutral900,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: FretColors.neutral500,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF0F1F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
