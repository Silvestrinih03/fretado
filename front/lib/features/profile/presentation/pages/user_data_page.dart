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

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileSummary(
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          userTypeLabel: snapshot.hasData
                              ? RegisterAccountTypeApiMapper.fromUserTypeId(
                                  snapshot.data!.userTypeId,
                                ).displayName
                              : '',
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _ProfileTextField(
                                label: 'NOME',
                                controller: _firstNameController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ProfileTextField(
                                label: 'SOBRENOME',
                                controller: _lastNameController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _ProfileTextField(
                          label: 'E-MAIL',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _ProfileTextField(
                          label: 'CPF',
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          canRequestFocus: false,
                          suffixIcon: Icons.check_rounded,
                        ),
                        const SizedBox(height: 20),
                        _ProfileTextField(
                          label: 'DATA DE NASCIMENTO',
                          controller: _birthDateController,
                          keyboardType: TextInputType.datetime,
                          suffixIcon: Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 20),
                        _ProfileTextField(
                          label: 'TELEFONE',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
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
      height: 96,
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9EAEE))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: FretColors.loginFooterLink,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          const Text(
            'Dados pessoais',
            style: TextStyle(
              color: FretColors.loginFooterLink,
              fontSize: 30,
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
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E4E6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FretColors.white, width: 3),
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
                size: 76,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: FretColors.secondaryVariation700,
                  borderRadius: BorderRadius.circular(18),
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
                  size: 21,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 28),
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
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userTypeLabel,
                    style: const TextStyle(
                      color: Color(0xFF4D4E57),
                      fontSize: 20,
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

  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.canRequestFocus = true,
    this.suffixIcon = Icons.edit_rounded,
    this.onSuffixTap,
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
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          canRequestFocus: canRequestFocus,
          style: const TextStyle(
            color: FretColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F1F3),
            contentPadding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.fromLTRB(42, 24, 42, 22),
      decoration: const BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: 62,
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
              fontSize: 21,
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

String _readErrorMessage(Object error) {
  final String message = error.toString();
  final int separatorIndex = message.indexOf(': ');

  if (separatorIndex == -1) {
    return message;
  }

  return message.substring(separatorIndex + 2);
}
