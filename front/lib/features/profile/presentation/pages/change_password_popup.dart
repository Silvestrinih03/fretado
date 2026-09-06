import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/profile_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widgets.dart';

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
    if (_isLoading) return;
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FretColors.screenBackground,
    body: SafeArea(child: Column(children: [
      const ProfileHeader(title: 'Segurança e senha'),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Form(key: _formKey, autovalidateMode: _autovalidateMode,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const ProfileSurface(child: Row(children: [
              ProfileIcon(icon: Icons.shield_outlined, size: 42),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Conta protegida', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FretColors.screenDark)),
                SizedBox(height: 2),
                // Temporary until password change dates are provided by the API.
                Text('Última alteração: há 2 meses', style: TextStyle(fontSize: 11, color: FretColors.screenMuted)),
              ])),
            ])),
            const SizedBox(height: 22),
            const Text('Alterar senha', style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: FretColors.screenDark)),
            const SizedBox(height: 14),
            ProfileField(label: 'Senha atual', controller: _currentPasswordController,
              password: true, textInputAction: TextInputAction.next, validator: _validateCurrentPassword),
            const SizedBox(height: 14),
            ProfileField(label: 'Nova senha', controller: _newPasswordController,
              password: true, textInputAction: TextInputAction.next,
              validator: (value) => _validateNewPassword(value, _currentPasswordController.text)),
            const SizedBox(height: 14),
            ProfileField(label: 'Confirmar nova senha', controller: _confirmPasswordController,
              password: true, textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (value) => _validatePasswordConfirmation(value, _newPasswordController.text)),
            const SizedBox(height: 12),
            const Text('Use no mínimo 8 caracteres com letras maiúsculas, minúsculas e números.',
              style: TextStyle(fontSize: 11, color: FretColors.screenMuted, height: 1.6)),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: FretColors.destructive600)),
            ],
          ]),
        ),
      )),
      ProfileSaveBar(label: 'Atualizar senha', isLoading: _isLoading, onPressed: _save),
    ])),
  );
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
  if (!RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'[a-z]').hasMatch(password) || !RegExp(r'[0-9]').hasMatch(password)) {
    return 'Use letras maiúsculas, minúsculas e números.';
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
