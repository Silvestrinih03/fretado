import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/register_account_type.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/profile_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../controllers/profile_controller.dart';
import 'change_password_popup.dart';

class UserDataPage extends StatefulWidget {
  const UserDataPage({super.key});

  @override
  State<UserDataPage> createState() => _UserDataPageState();
}

class _UserDataPageState extends State<UserDataPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(
    text: '**************',
  );

  late final int _userId;
  late final Future<MyselfUserModel> _userFuture;
  late final HttpService _httpService;
  late final ProfileController _profileController;
  bool _didFillControllers = false;
  bool _isSaving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final MyselfService myselfService = MyselfService();
    _userId = myselfService.currentUserId ?? 5;

    _userFuture = myselfService.getMyself(_userId);
    _httpService = HttpService();
    _profileController = ProfileController(
      ProfileRepositoryImpl(
        ProfileDatasource(_httpService),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _httpService.dispose();
    super.dispose();
  }

  void _fillControllers(MyselfUserModel user) {
    if (_didFillControllers) {
      return;
    }

    _fillUserData(user);
    _didFillControllers = true;
  }

  void _fillUserData(MyselfUserModel user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _cpfController.text = _formatCpf(user.cpf);
    _birthDateController.text = _formatBirthDate(user.birthDate);
    _phoneController.text = _formatPhone(user.phone);
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    setState(() => _isSaving = true);

    try {
      final MyselfUserModel updatedUser = await _profileController.updateUser(
        userId: _userId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        birthDate: _birthDateController.text,
        phone: _phoneController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _fillUserData(updatedUser);
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados salvos com sucesso.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            const _UserDataHeader(),
            Expanded(
              child: FutureBuilder<MyselfUserModel>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData) {
                    _fillControllers(snapshot.data!);
                  }

                  return Form(
                    key: _formKey,
                    autovalidateMode: _autovalidateMode,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileSummary(
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          userTypeLabel: snapshot.hasData
                              ? RegisterAccountTypeApiMapper.fromUserTypeId(
                                  snapshot.data!.userTypeId ??
                                      MyselfService().currentUserTypeId ??
                                      1,
                                ).displayName
                              : '',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ProfileTextField(
                                label: 'NOME',
                                controller: _firstNameController,
                                validator: (value) =>
                                    _validateRequiredField(value, 'nome'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileTextField(
                                label: 'SOBRENOME',
                                controller: _lastNameController,
                                validator: (value) =>
                                    _validateRequiredField(value, 'sobrenome'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'E-MAIL',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'CPF',
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          canRequestFocus: false,
                          suffixIcon: Icons.check_rounded,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'DATA DE NASCIMENTO',
                          controller: _birthDateController,
                          keyboardType: TextInputType.datetime,
                          suffixIcon: Icons.calendar_today_outlined,
                          validator: _validateOptionalBirthDate,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'TELEFONE',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: _validateOptionalPhone,
                        ),
                        const SizedBox(height: 14),
                        _ProfileTextField(
                          label: 'SENHA',
                          controller: _passwordController,
                          obscureText: true,
                          readOnly: true,
                          canRequestFocus: false,
                          suffixIcon: Icons.edit_rounded,
                          onSuffixTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => const ChangePasswordPopup(),
                            );
                          },
                        ),
                      ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _SaveBar(onPressed: _save, isLoading: _isSaving),
          ],
        ),
      ),
    );
  }
}

class _UserDataHeader extends StatelessWidget {
  const _UserDataHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9EAEE))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: FretColors.loginFooterLink,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Dados pessoais',
            style: TextStyle(
              color: FretColors.loginFooterLink,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String userTypeLabel;

  const _ProfileSummary({
    required this.firstNameController,
    required this.lastNameController,
    required this.userTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E4E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FretColors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_circle_outlined,
                color: Color(0xFF4A4B55),
                size: 48,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: FretColors.secondaryVariation700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 14,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: FretColors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              firstNameController,
              lastNameController,
            ]),
            builder: (context, _) {
              final String fullName =
                  '${firstNameController.text} ${lastNameController.text}'
                      .trim();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isEmpty ? 'Usuário' : fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FretColors.loginFooterLink,
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userTypeLabel,
                    style: const TextStyle(
                      color: Color(0xFF4D4E57),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ), 
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool canRequestFocus;
  final IconData suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.canRequestFocus = true,
    this.suffixIcon = Icons.edit_rounded,
    this.onSuffixTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7A7D88),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          canRequestFocus: canRequestFocus,
          validator: validator,
          style: const TextStyle(
            color: FretColors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F1F3),
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              onPressed: onSuffixTap,
              icon: Icon(
                suffixIcon,
                color: const Color(0xFFA7A9B1),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  final Future<void> Function() onPressed;
  final bool isLoading;

  const _SaveBar({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  await onPressed();
                },
          style: ElevatedButton.styleFrom(
            elevation: 10,
            shadowColor: FretColors.loginFooterLink.withOpacity(0.3),
            backgroundColor: const Color(0xFF070873),
            foregroundColor: FretColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            isLoading ? 'Salvando...' : 'Salvar',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatBirthDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return '${_twoDigits(parsed.day)}/${_twoDigits(parsed.month)}/${parsed.year}';
}

String _formatCpf(String value) {
  final String digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) {
    return value;
  }

  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
}

String _formatPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }

  final String digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }

  return value;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String? _validateRequiredField(String? value, String fieldName) {
  if ((value ?? '').trim().isEmpty) {
    return 'Informe seu $fieldName.';
  }

  return null;
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

String? _validateOptionalBirthDate(String? value) {
  final String raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }

  final String digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 8) {
    return 'Informe a data no formato DD/MM/AAAA.';
  }

  final int day = int.parse(digits.substring(0, 2));
  final int month = int.parse(digits.substring(2, 4));
  final int year = int.parse(digits.substring(4, 8));
  final DateTime date = DateTime(year, month, day);

  final bool isValidDate =
      date.day == day && date.month == month && date.year == year;
  if (!isValidDate) {
    return 'Informe uma data válida.';
  }

  if (date.isAfter(DateTime.now())) {
    return 'A data de nascimento não pode ser futura.';
  }

  return null;
}

String? _validateOptionalPhone(String? value) {
  final String digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return null;
  }

  if (digits.length < 10 || digits.length > 11) {
    return 'Informe um telefone válido.';
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
