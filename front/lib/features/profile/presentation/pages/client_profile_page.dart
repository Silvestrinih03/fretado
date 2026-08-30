import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import 'change_password_popup.dart';
import 'user_data_page.dart';

class ClientProfilePage extends StatefulWidget {
  final int userId;

  const ClientProfilePage({super.key, required this.userId});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  late final MyselfService _myselfService;
  late final Future<MyselfUserModel> _myselfFuture;

  @override
  void initState() {
    super.initState();
    _myselfService = MyselfService();
    _myselfService.currentUserId = widget.userId;
    _myselfFuture = _myselfService.getMyself(widget.userId);
  }

  Future<void> _logout() async {
    await _myselfService.logout();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _openUserData() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const UserDataPage()),
    );
  }

  void _openAccountSettings() {
    showDialog<void>(
      context: context,
      builder: (_) => const ChangePasswordPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FretColors.appBackground,
      body: SafeArea(
        child: FutureBuilder<MyselfUserModel>(
          future: _myselfFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final String fullName = user?.fullName.trim().isNotEmpty == true
                ? user!.fullName
                : 'Cliente';
            final String email = user?.email.trim().isNotEmpty == true
                ? user!.email
                : 'Conta FreteJ\u00e1';

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              children: [
                const Text(
                  'Perfil',
                  style: TextStyle(
                    color: FretColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 18),
                FretSurfaceCard(
                  padding: const EdgeInsets.all(16),
                  radius: 14,
                  child: Row(
                    children: [
                      const FretIconBox(
                        icon: Icons.person_outline_rounded,
                        size: 48,
                        iconSize: 24,
                        radius: 14,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FretColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FretColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ProfileActionTile(
                  icon: Icons.account_circle_outlined,
                  title: 'Dados pessoais',
                  subtitle: 'Editar nome, e-mail, telefone e senha',
                  onTap: _openUserData,
                ),
                const SizedBox(height: 10),
                _ProfileActionTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Configura\u00e7\u00f5es da conta',
                  subtitle: 'Alterar senha de acesso',
                  onTap: _openAccountSettings,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text('Sair'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FretColors.destructive600,
                      side: const BorderSide(color: FretColors.destructive200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FretShortcutTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
