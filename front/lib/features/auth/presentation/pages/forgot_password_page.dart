import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  late final AuthController _authController;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    final HttpService httpService = HttpService();
    final AuthDatasource datasource = AuthDatasource(httpService);
    final AuthRepositoryImpl repository = AuthRepositoryImpl(datasource);
    _authController = AuthController(repository);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryEmail() async {
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final bool isSuccess = await _authController.forgotPassword(
      email: _emailController.text,
    );

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      setState(() {
        _emailSent = true;
      });
      return;
    }

    showFretErrorPopup(
      context,
      message:
          _authController.errorMessage ??
          'Nao foi possivel enviar o email de recuperacao.',
    );
  }

  void _backToLogin() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) => FretAuthScreen(
        title: _emailSent ? 'Confira seu email' : 'Recuperar senha',
        titleSize: 24,
        subtitle: _emailSent
            ? 'Se o email estiver cadastrado, você receberá um link para recuperar sua senha.'
            : 'Informe o email cadastrado.',
        footer: TextButton.icon(
          onPressed: _backToLogin,
          icon: const Icon(Icons.chevron_left_rounded, size: 16),
          label: const Text('Voltar para login'),
          style: TextButton.styleFrom(
            foregroundColor: FretColors.screenMuted,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child: AbsorbPointer(
          absorbing: _authController.isLoading,
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_emailSent) ...[
                  const FretAuthFieldLabel(text: 'Email'),
                  const SizedBox(height: 8),
                  FretAuthTextField(
                    redesigned: true,
                    controller: _emailController,
                    hintText: 'nome@email.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _sendRecoveryEmail(),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  FretPrimaryButton(
                    label: 'Enviar email',
                    onPressed: _sendRecoveryEmail,
                    loading: _authController.isLoading,
                    height: 54,
                    radius: 14,
                    backgroundColor: FretColors.screenDark,
                    foregroundColor: FretColors.white,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.56,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  final String trimmedValue = (value ?? '').trim();
  if (trimmedValue.isEmpty) {
    return 'Informe seu email.';
  }

  final bool validEmail = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(trimmedValue);

  if (!validEmail) {
    return 'Informe um email valido.';
  }

  return null;
}
