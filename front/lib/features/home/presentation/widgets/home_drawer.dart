import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../../profile/presentation/pages/user_data_page.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: FretColors.loginFooterLink,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: FretColors.white,
                    child: Icon(
                      Icons.person,
                      color: FretColors.loginFooterLink,
                    ),
                  ),
                  SizedBox(height: 12),
                  _DrawerUserName(),
                  SizedBox(height: 4),
                  Text(
                    'Gerencie seus dados',
                    style: TextStyle(color: FretColors.primary100),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.supervised_user_circle_outlined,
              label: 'Dados pessoais',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UserDataPage(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.credit_card_outlined,
              label: 'Métodos de pagamento',
              onTap: () => Navigator.of(context).pop(),
            ),
            // _DrawerItem(
            //   icon: Icons.settings_outlined,
            //   label: 'Configurações',
            //   onTap: () => Navigator.of(context).pop(),
            // ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerUserName extends StatefulWidget {
  const _DrawerUserName();

  @override
  State<_DrawerUserName> createState() => _DrawerUserNameState();
}

class _DrawerUserNameState extends State<_DrawerUserName> {
  late final Future<MyselfUserModel> _myselfFuture;

  @override
  void initState() {
    super.initState();
    final MyselfService myselfService = MyselfService();
    final int userId = myselfService.currentUserId ?? 5;

    _myselfFuture = myselfService.getMyself(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MyselfUserModel>(
      future: _myselfFuture,
      builder: (context, snapshot) {
        final String name = snapshot.data?.fullName.isNotEmpty == true
            ? snapshot.data!.fullName
            : 'Usuário';

        return Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FretColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: FretColors.loginFooterLink),
      title: Text(
        label,
        style: const TextStyle(
          color: FretColors.neutral800,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
