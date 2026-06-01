import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../controllers/auth_controller.dart';
import '../../../register/presentation/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AuthController _authController;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _obscurePassword = true;

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
    _passwordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _openRegisterPage() async {
    final bool? didRegister = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const RegisterPage()));

    if (!mounted) {
      return;
    }

    if (didRegister == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado. Faça seu login.')),
      );
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final bool isSuccess = await _authController.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      final MyselfService myselfService = MyselfService();
      myselfService.currentUserId = _authController.currentUser?.id;

      final int userTypeId = _authController.currentUser?.userTypeId ?? 2;
      myselfService.currentUserTypeId = userTypeId;
      final HomeProfileEnum profile = HomeProfileMapper.fromUserTypeId(userTypeId);
      final int? userId = _authController.currentUser?.id;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomePage(
            profile: profile,
            userId: userId,
            userTypeId: userTypeId,
          ),
        ),
      );
      return;
    }

    final String errorMessage =
        _authController.errorMessage ?? 'Falha no login.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
                  final double logoHeight =
                      constraints.maxWidth < 390 ? 58 : isCompact ? 68 : 96;
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
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _autovalidateMode,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FretAuthBrandHeader(height: logoHeight),
                                    SizedBox(width: headerGap),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FretAuthHeading(text: 'Bem-vindo'),
                                          SizedBox(height: 6),
                                          FretAuthSubtitle(
                                            text:
                                                'Acesse ou cadastre-se para continuar.',
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
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 16),
                                const FretAuthFieldLabel(text: 'Senha'),
                                const SizedBox(height: 8),
                                FretAuthTextField(
                                  controller: _passwordController,
                                  hintText: '•••••••••',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  validator: _validatePassword,
                                  suffixIcon: IconButton(
                                    onPressed: _togglePasswordVisibility,
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: FretColors.loginInputIcon,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FretAuthForgotPasswordLink(onPressed: () {}),
                                const SizedBox(height: 22),
                                FretPrimaryGradientButton(
                                  label: _authController.isLoading
                                      ? 'Entrando...'
                                      : 'Entrar',
                                  onPressed: _login,
                                ),
                                const SizedBox(height: 24),
                                const Divider(
                                  color: FretColors.loginDivider,
                                  height: 1,
                                ),
                                const SizedBox(height: 24),
                                FretAuthFooterPrompt(
                                  onSignUpPressed: _openRegisterPage,
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

String? _validateEmail(String? value) {
  final String trimmedValue = (value ?? '').trim();
  if (trimmedValue.isEmpty) {
    return 'Informe seu email.';
  }

  final bool validEmail = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(trimmedValue);

  if (!validEmail) {
    return 'Informe um email válido.';
  }

  return null;
}

String? _validatePassword(String? value) {
  if ((value ?? '').isEmpty) {
    return 'Informe sua senha.';
  }

  return null;
}
