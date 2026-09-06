import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../controllers/auth_controller.dart';
import 'forgot_password_page.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cadastro realizado.')));
    }
  }

  Future<void> _openForgotPasswordPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage()));
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
      final int? userId = _authController.currentUser?.id;

      final int userTypeId = _authController.currentUser?.userTypeId ?? 2;
      if (userId != null) {
        await myselfService.saveSession(
          userId: userId,
          userTypeId: userTypeId,
          accessToken: _authController.currentUser?.accessToken,
        );
      }
      final HomeProfileEnum profile = HomeProfileMapper.fromUserTypeId(
        userTypeId,
      );

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
    showFretErrorPopup(context, message: errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) => FretAuthScreen(
        title: 'Bem-vindo',
        subtitle: 'Acesse ou cadastre-se para continuar.',
        child: AbsorbPointer(
          absorbing: _authController.isLoading,
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FretAuthFieldLabel(text: 'Email'),
                const SizedBox(height: 8),
                FretAuthTextField(
                  redesigned: true,
                  controller: _emailController,
                  hintText: 'nome@email.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),
                const FretAuthFieldLabel(text: 'Senha'),
                const SizedBox(height: 8),
                FretAuthTextField(
                  redesigned: true,
                  controller: _passwordController,
                  hintText: '•••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  suffixIcon: IconButton(
                    onPressed: _togglePasswordVisibility,
                    tooltip: _obscurePassword
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: FretColors.screenMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openForgotPasswordPage,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FretColors.screenGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FretPrimaryButton(
                  label: 'Entrar',
                  onPressed: _login,
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: FretColors.screenBorder)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            fontSize: 11,
                            color: FretColors.screenMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: FretColors.screenBorder)),
                    ],
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'N?o possui uma conta? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: FretColors.screenMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: _openRegisterPage,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cadastre-se',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FretColors.screenDark,
                        ),
                      ),
                    ),
                  ],
                ),
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
