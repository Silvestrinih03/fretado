import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/enums/register_account_type.dart';
import '../../../../core/enums/register_step.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../../auth/data/datasources/auth_datasource.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../home/presentation/pages/home_page.dart';
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
  final GlobalKey<FormState> _stepTwoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _stepThreeFormKey = GlobalKey<FormState>();
  RegisterStepEnum _currentStep = RegisterStepEnum.accountType;
  UserTypeEnum? _selectedAccountType;

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
  AutovalidateMode _stepTwoAutovalidateMode = AutovalidateMode.disabled;
  AutovalidateMode _stepThreeAutovalidateMode = AutovalidateMode.disabled;
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
    if (_currentStep == RegisterStepEnum.personalData) {
      setState(() => _currentStep = RegisterStepEnum.basicData);
      return;
    }
    if (_currentStep == RegisterStepEnum.basicData) {
      setState(() => _currentStep = RegisterStepEnum.accountType);
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _onAccountTypeSelected(UserTypeEnum type) {
    setState(() {
      _selectedAccountType = type;
      _currentStep = RegisterStepEnum.basicData;
    });
  }

  void _goToStepThree() {
    FocusScope.of(context).unfocus();

    final bool isFormValid = _stepTwoFormKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _stepTwoAutovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    setState(() => _currentStep = RegisterStepEnum.personalData);
  }

  Future<void> _finishRegister() async {
    FocusScope.of(context).unfocus();

    if (_selectedAccountType == null) {
      showFretErrorPopup(
        context,
        message: 'Selecione o tipo de conta para continuar.',
      );
      return;
    }

    final bool isFormValid =
        _stepThreeFormKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _stepThreeAutovalidateMode = AutovalidateMode.onUserInteraction;
      });
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
      final registeredUser = _registerController.registeredUser;
      if (registeredUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro concluído com sucesso.')),
        );
        Navigator.of(context).pop(true);
        return;
      }

      final String? accessToken = await _loginRegisteredUser();
      if (accessToken == null) {
        await MyselfService().logout();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro concluido. Entre para continuar.'),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      await MyselfService().saveSession(
        userId: registeredUser.id,
        userTypeId: registeredUser.userTypeId,
        accessToken: accessToken,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro concluído com sucesso.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => HomePage(
            profile: HomeProfileMapper.fromUserTypeId(
              registeredUser.userTypeId,
            ),
            userId: registeredUser.id,
            userTypeId: registeredUser.userTypeId,
          ),
        ),
        (route) => false,
      );
      return;
    }

    final String message =
        _registerController.errorMessage ??
        'Não foi possível concluir cadastro.';
    showFretErrorPopup(context, message: message);
  }

  Future<String?> _loginRegisteredUser() async {
    final HttpService httpService = HttpService();
    try {
      final user = await AuthDatasource(httpService).login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      return user.accessToken;
    } catch (_) {
      return null;
    } finally {
      httpService.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _registerController,
      builder: (context, _) {
        return RegisterFlowShell(
          stepIndex: _currentStepIndex,
          showBackButton: _currentStep != RegisterStepEnum.accountType,
          onBackPressed: _handleBack,
          activeDotColor: _currentStepDotColor,
          child: _buildCurrentStep(),
        );
      },
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case RegisterStepEnum.accountType:
        return RegisterStepOne(
          selectedType: _selectedAccountType,
          onTypeSelected: _onAccountTypeSelected,
        );
      case RegisterStepEnum.basicData:
        return RegisterStepTwo(
          formKey: _stepTwoFormKey,
          autovalidateMode: _stepTwoAutovalidateMode,
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
      case RegisterStepEnum.personalData:
        return RegisterStepThree(
          formKey: _stepThreeFormKey,
          autovalidateMode: _stepThreeAutovalidateMode,
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
