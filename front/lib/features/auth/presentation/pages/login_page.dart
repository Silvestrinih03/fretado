import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AuthController _authController;
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

    final bool isSuccess = await _authController.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
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
          backgroundColor: FretColors.loginBackground,
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: _authController.isLoading,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: FretAuthCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const FretAuthBrandHeader(),
                                const SizedBox(height: 44),
                                const FretAuthHeading(text: 'Bem-vindo'),
                                const SizedBox(height: 12),
                                const FretAuthSubtitle(
                                  text: 'Acesse sua conta para continuar.',
                                ),
                                const SizedBox(height: 44),
                                const FretAuthFieldLabel(text: 'Email'),
                                const SizedBox(height: 14),
                                FretAuthTextField(
                                  controller: _emailController,
                                  hintText: 'nome@email.com',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                ),
                                const SizedBox(height: 24),
                                const FretAuthFieldLabel(text: 'Senha'),
                                const SizedBox(height: 14),
                                FretAuthTextField(
                                  controller: _passwordController,
                                  hintText: '•••••••••',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    onPressed: _togglePasswordVisibility,
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: FretColors.loginInputIcon,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FretAuthForgotPasswordLink(onPressed: () {}),
                                const SizedBox(height: 32),
                                FretPrimaryGradientButton(
                                  label: _authController.isLoading
                                      ? 'Entrando...'
                                      : 'Entrar',
                                  onPressed: _login,
                                ),
                                const SizedBox(height: 34),
                                const Divider(
                                  color: FretColors.loginDivider,
                                  height: 1,
                                ),
                                const SizedBox(height: 34),
                                FretAuthFooterPrompt(
                                  onSignUpPressed: _openRegisterPage,
                                ),
                                if (_authController.isLoading) ...[
                                  const SizedBox(height: 18),
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
