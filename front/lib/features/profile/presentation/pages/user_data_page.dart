import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/register_account_type.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/profile_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widgets.dart';

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


  late final int _userId;
  late Future<MyselfUserModel> _userFuture;
  late final HttpService _httpService;
  late final ProfileController _profileController;
  bool _didFillControllers = false;
  bool _isSaving = false;
  bool _userLoaded = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final MyselfService myselfService = MyselfService();
    _userId = myselfService.currentUserId ?? 0;

    _userFuture = _loadUser();
    _httpService = HttpService();
    _profileController = ProfileController(
      ProfileRepositoryImpl(
        ProfileDatasource(_httpService),
      ),
    );
  }

  Future<MyselfUserModel> _loadUser() async {
    final user = await MyselfService().getMyself(_userId);
    if (mounted) setState(() => _userLoaded = true);
    return user;
  }

  Future<void> _selectBirthDate() async {
    final digits = _birthDateController.text.replaceAll(RegExp(r'\D'), '');
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 18, now.month, now.day);
    if (digits.length == 8) {
      final parsed = DateTime(int.parse(digits.substring(4)),
        int.parse(digits.substring(2, 4)), int.parse(digits.substring(0, 2)));
      if (!parsed.isAfter(now) && !parsed.isBefore(DateTime(1900))) initial = parsed;
    }
    final selected = await showDatePicker(context: context, initialDate: initial,
      firstDate: DateTime(1900), lastDate: now);
    if (selected != null && mounted) {
      _birthDateController.text = _formatBirthDate(selected.toIso8601String());
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
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
      showFretErrorPopup(context, message: _readErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FretColors.screenBackground,
    body: SafeArea(child: Column(children: [
      const ProfileHeader(title: 'Dados pessoais'),
      Expanded(child: FutureBuilder<MyselfUserModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: FretColors.screenGold));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Não foi possível carregar seus dados.'),
              TextButton(onPressed: () => setState(() { _userFuture = _loadUser(); }),
                child: const Text('Tentar novamente')),
            ]));
          }
          _fillControllers(snapshot.data!);
          final type = RegisterAccountTypeApiMapper.fromUserTypeId(
            snapshot.data!.userTypeId ?? MyselfService().currentUserTypeId ?? 1).displayName;
          return Form(
            key: _formKey, autovalidateMode: _autovalidateMode,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_firstNameController, _lastNameController, _emailController]),
                  builder: (context, _) {
                    final name = '${_firstNameController.text} ${_lastNameController.text}'.trim();
                    return Row(children: [
                      ProfileAvatar(name: name, size: 68),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: FretColors.screenDark)),
                        const SizedBox(height: 3),
                        Text('$type · ${_emailController.text}',
                          style: const TextStyle(fontSize: 12, color: FretColors.screenMuted)),
                      ])),
                    ]);
                  },
                ),
                const SizedBox(height: 22),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: ProfileField(label: 'Nome', controller: _firstNameController,
                    validator: (value) => _validateRequiredField(value, 'nome'))),
                  const SizedBox(width: 10),
                  Expanded(child: ProfileField(label: 'Sobrenome', controller: _lastNameController,
                    validator: (value) => _validateRequiredField(value, 'sobrenome'))),
                ]),
                const SizedBox(height: 14),
                ProfileField(label: 'E-mail', controller: _emailController,
                  keyboardType: TextInputType.emailAddress, validator: _validateEmail),
                const SizedBox(height: 14),
                ProfileField(label: 'CPF', controller: _cpfController, readOnly: true, icon: Icons.check_rounded),
                const SizedBox(height: 14),
                ProfileField(label: 'Data de nascimento', controller: _birthDateController,
                  keyboardType: TextInputType.datetime, icon: Icons.calendar_today_outlined,
                  onIconTap: _selectBirthDate, validator: _validateOptionalBirthDate),
                const SizedBox(height: 14),
                ProfileField(label: 'Telefone', controller: _phoneController,
                  keyboardType: TextInputType.phone, validator: _validateOptionalPhone),
              ]),
            ),
          );
        },
      )),
      ProfileSaveBar(label: 'Salvar alterações', isLoading: _isSaving,
        onPressed: _userLoaded ? _save : null),
    ])),
  );
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
