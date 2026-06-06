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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _authController.errorMessage ??
              'Nao foi possivel enviar o email de recuperacao.',
        ),
      ),
    );
  }

  void _backToLogin() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: FretColors.white,
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: _authController.isLoading,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isCompact = constraints.maxWidth < 520;
                  final double logoHeight = constraints.maxWidth < 390
                      ? 58
                      : isCompact
                      ? 68
                      : 96;
                  final double headerGap = isCompact ? 8 : 14;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: FretAuthCard(
                            child: _emailSent
                                ? _RecoveryEmailSentContent(
                                    email: _emailController.text.trim(),
                                    onBackToLogin: _backToLogin,
                                  )
                                : Form(
                                    key: _formKey,
                                    autovalidateMode: _autovalidateMode,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            FretAuthBrandHeader(
                                              height: logoHeight,
                                            ),
                                            SizedBox(width: headerGap),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  FretAuthHeading(
                                                    text: 'Recuperar senha',
                                                  ),
                                                  SizedBox(height: 6),
                                                  FretAuthSubtitle(
                                                    text:
                                                        'Informe o email cadastrado.',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        const FretAuthFieldLabel(text: 'Email'),
                                        const SizedBox(height: 8),
                                        FretAuthTextField(
                                          controller: _emailController,
                                          hintText: 'nome@email.com',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          prefixIcon:
                                              Icons.mail_outline_rounded,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) =>
                                              _sendRecoveryEmail(),
                                          validator: _validateEmail,
                                        ),
                                        const SizedBox(height: 22),
                                        FretPrimaryGradientButton(
                                          label: _authController.isLoading
                                              ? 'Enviando...'
                                              : 'Enviar email',
                                          onPressed: _sendRecoveryEmail,
                                        ),
                                        const SizedBox(height: 18),
                                        TextButton(
                                          onPressed: _backToLogin,
                                          child: const Text(
                                            'Voltar para login',
                                            style: TextStyle(
                                              color: FretColors.loginFooterLink,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (_authController.isLoading) ...[
                                          const SizedBox(height: 12),
                                          const LinearProgressIndicator(
                                            color: FretColors.loginButtonStart,
                                            minHeight: 3,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecoveryEmailSentContent extends StatelessWidget {
  final String email;
  final VoidCallback onBackToLogin;

  const _RecoveryEmailSentContent({
    required this.email,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FretAuthBrandHeader(height: 72),
        const SizedBox(height: 20),
        const FretAuthHeading(text: 'Confira seu email'),
        const SizedBox(height: 8),
        Text(
          email.isEmpty
              ? 'Enviamos o link de recuperacao.'
              : 'Enviamos o link de recuperacao para $email.',
          style: const TextStyle(
            color: FretColors.loginSubtitle,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),
        FretPrimaryGradientButton(
          label: 'Voltar para login',
          onPressed: onBackToLogin,
        ),
      ],
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
