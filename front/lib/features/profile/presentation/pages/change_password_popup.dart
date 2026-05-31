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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  HttpService? _httpService;
  String? _errorMessage;
  bool _isLoading = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

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
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        _errorMessage = null;
      });
      return;
    }

    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: FretColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Alteração de senha',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: FretColors.loginFooterLink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Digite a sua senha atual e a nova senha para alterar sua senha de acesso.',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: FretColors.neutral500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                children: [
                  _PasswordPopupField(
                    controller: _currentPasswordController,
                    hintText: 'Senha atual.',
                    textInputAction: TextInputAction.next,
                    validator: _validateCurrentPassword,
                  ),
                  const SizedBox(height: 14),
                  _PasswordPopupField(
                    controller: _newPasswordController,
                    hintText: 'Digite a nova senha.',
                    textInputAction: TextInputAction.next,
                    validator: (value) => _validateNewPassword(
                      value,
                      _currentPasswordController.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PasswordPopupField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirme a nova senha.',
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    validator: (value) => _validatePasswordConfirmation(
                      value,
                      _newPasswordController.text,
                    ),
                  ),
                ],
              ),
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
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 150,
                height: 44,
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
                      fontSize: 15,
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

String? _validateCurrentPassword(String? value) {
  final String password = (value ?? '').trim();
  if (password.isEmpty) {
    return 'Informe sua senha atual.';
  }
  if (password.length < 8) {
    return 'A senha deve ter pelo menos 8 caracteres.';
  }

  return null;
}

String? _validateNewPassword(String? value, String currentPassword) {
  final String password = (value ?? '').trim();
  if (password.isEmpty) {
    return 'Informe a nova senha.';
  }
  if (password.length < 8) {
    return 'A senha deve ter pelo menos 8 caracteres.';
  }
  if (password == currentPassword.trim()) {
    return 'A nova senha deve ser diferente da senha atual.';
  }

  return null;
}

String? _validatePasswordConfirmation(String? value, String newPassword) {
  final String confirmation = (value ?? '').trim();
  if (confirmation.isEmpty) {
    return 'Confirme a nova senha.';
  }
  if (confirmation != newPassword.trim()) {
    return 'A nova senha e a confirmação não conferem.';
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
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const _PasswordPopupField({
    required this.controller,
    required this.hintText,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: FretColors.neutral900,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: FretColors.neutral500,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF0F1F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
