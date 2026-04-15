import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/register_account_type.dart';
import '../../../../core/enums/register_step.dart';
import '../../../../core/services/http_service.dart';
import '../../data/datasources/register_datasource.dart';
import '../../data/repositories/register_repository_impl.dart';
import '../controllers/register_controller.dart';
import '../widgets/register_flow_shell.dart';
import '../widgets/register_step_one.dart';
import '../widgets/register_step_three.dart';
import '../widgets/register_step_two.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  RegisterStep _currentStep = RegisterStep.accountType;
  RegisterAccountType? _selectedAccountType;

  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late final RegisterController _registerController;

  @override
  void initState() {
    super.initState();
    final HttpService httpService = HttpService();
    final RegisterDatasource datasource = RegisterDatasource(httpService);
    final RegisterRepositoryImpl repository = RegisterRepositoryImpl(
      datasource,
    );
    _registerController = RegisterController(repository);
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _registerController.dispose();
    super.dispose();
  }

  int get _currentStepIndex => _currentStep.index;

  Color get _currentStepDotColor {
    return FretColors.loginFooterLink;
  }

  void _handleBack() {
    if (_currentStep == RegisterStep.personalData) {
      setState(() => _currentStep = RegisterStep.basicData);
      return;
    }
    if (_currentStep == RegisterStep.basicData) {
      setState(() => _currentStep = RegisterStep.accountType);
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _onAccountTypeSelected(RegisterAccountType type) {
    setState(() {
      _selectedAccountType = type;
      _currentStep = RegisterStep.basicData;
    });
  }

  void _goToStepThree() {
    final bool valid = _registerController.validateStepTwo(
      cpf: _cpfController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!valid) {
      final String message =
          _registerController.errorMessage ?? 'Revise os dados para continuar.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() => _currentStep = RegisterStep.personalData);
  }

  Future<void> _finishRegister() async {
    if (_selectedAccountType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o tipo de conta para continuar.'),
        ),
      );
      return;
    }

    final bool success = await _registerController.register(
      cpf: _cpfController.text,
      email: _emailController.text,
      password: _passwordController.text,
      userTypeId: _selectedAccountType!.userTypeId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      birthDate: _birthDateController.text,
      phone: _phoneController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro concluído com sucesso.')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    final String message =
        _registerController.errorMessage ??
        'Não foi possível concluir cadastro.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _registerController,
      builder: (context, _) {
        return RegisterFlowShell(
          stepIndex: _currentStepIndex,
          showBackButton: _currentStep != RegisterStep.accountType,
          onBackPressed: _handleBack,
          activeDotColor: _currentStepDotColor,
          child: _buildCurrentStep(),
        );
      },
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case RegisterStep.accountType:
        return RegisterStepOne(
          selectedType: _selectedAccountType,
          onTypeSelected: _onAccountTypeSelected,
        );
      case RegisterStep.basicData:
        return RegisterStepTwo(
          cpfController: _cpfController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          obscurePassword: _obscurePassword,
          obscureConfirmPassword: _obscureConfirmPassword,
          onTogglePassword: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          onToggleConfirmPassword: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
          onContinue: _goToStepThree,
        );
      case RegisterStep.personalData:
        return RegisterStepThree(
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          birthDateController: _birthDateController,
          phoneController: _phoneController,
          isLoading: _registerController.isLoading,
          onFinish: _finishRegister,
        );
    }
  }
}
