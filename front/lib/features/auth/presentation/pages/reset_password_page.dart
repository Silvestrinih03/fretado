import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../controllers/auth_controller.dart';
import 'forgot_password_page.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final AuthController _authController;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  bool get _hasToken => widget.token.trim().isNotEmpty;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final bool isSuccess = await _authController.resetPassword(
      token: widget.token,
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (_) => false,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso.')),
      );
      return;
    }

    showFretErrorPopup(
      context,
      message: _authController.errorMessage ??
          'Nao foi possivel redefinir sua senha.',
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmationVisibility() {
    setState(() {
      _obscureConfirmation = !_obscureConfirmation;
    });
  }

  void _requestNewLink() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage()),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
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
                            child: _hasToken
                                ? Form(
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
                                                    text: 'Nova senha',
                                                  ),
                                                  SizedBox(height: 6),
                                                  FretAuthSubtitle(
                                                    text:
                                                        'Crie uma senha segura.',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        const FretAuthFieldLabel(
                                          text: 'Nova senha',
                                        ),
                                        const SizedBox(height: 8),
                                        FretAuthTextField(
                                          controller: _passwordController,
                                          hintText: '********',
                                          obscureText: _obscurePassword,
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          textInputAction: TextInputAction.next,
                                          validator: _validatePassword,
                                          suffixIcon: IconButton(
                                            onPressed:
                                                _togglePasswordVisibility,
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: FretColors.loginInputIcon,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const FretAuthFieldLabel(
                                          text: 'Confirmar senha',
                                        ),
                                        const SizedBox(height: 8),
                                        FretAuthTextField(
                                          controller:
                                              _confirmPasswordController,
                                          hintText: '********',
                                          obscureText: _obscureConfirmation,
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) =>
                                              _resetPassword(),
                                          validator: (value) =>
                                              _validateConfirmation(
                                            value,
                                            _passwordController.text,
                                          ),
                                          suffixIcon: IconButton(
                                            onPressed:
                                                _toggleConfirmationVisibility,
                                            icon: Icon(
                                              _obscureConfirmation
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: FretColors.loginInputIcon,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        FretPrimaryGradientButton(
                                          label: _authController.isLoading
                                              ? 'Salvando...'
                                              : 'Salvar senha',
                                          onPressed: _resetPassword,
                                        ),
                                        const SizedBox(height: 18),
                                        TextButton(
                                          onPressed: _goToLogin,
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
                                  )
                                : _InvalidResetLinkContent(
                                    onRequestNewLink: _requestNewLink,
                                    onBackToLogin: _goToLogin,
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

class _InvalidResetLinkContent extends StatelessWidget {
  final VoidCallback onRequestNewLink;
  final VoidCallback onBackToLogin;

  const _InvalidResetLinkContent({
    required this.onRequestNewLink,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FretAuthBrandHeader(height: 72),
        const SizedBox(height: 20),
        const FretAuthHeading(text: 'Link invalido'),
        const SizedBox(height: 8),
        const Text(
          'Solicite um novo link para redefinir sua senha.',
          style: TextStyle(
            color: FretColors.loginSubtitle,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),
        FretPrimaryGradientButton(
          label: 'Novo link',
          onPressed: onRequestNewLink,
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: onBackToLogin,
          child: const Text(
            'Voltar para login',
            style: TextStyle(
              color: FretColors.loginFooterLink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String? _validatePassword(String? value) {
  final String password = value ?? '';
  if (password.isEmpty) {
    return 'Informe a nova senha.';
  }

  if (password.length < 8) {
    return 'A senha deve ter pelo menos 8 caracteres.';
  }

  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Use pelo menos uma letra maiuscula.';
  }

  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Use pelo menos uma letra minuscula.';
  }

  if (!RegExp(r'\d').hasMatch(password)) {
    return 'Use pelo menos um numero.';
  }

  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
    return 'Use pelo menos um caractere especial.';
  }

  return null;
}

String? _validateConfirmation(String? value, String password) {
  final String confirmation = value ?? '';
  if (confirmation.isEmpty) {
    return 'Confirme a nova senha.';
  }

  if (confirmation != password) {
    return 'As senhas nao conferem.';
  }

  return null;
}
