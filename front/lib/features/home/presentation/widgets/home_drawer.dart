import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../../driver_operations/presentation/pages/driver_operations_page.dart';
import '../../../documents/presentation/pages/my_documents.dart';
import '../../../payments/presentation/pages/my_payment_methods_page.dart';
import '../../../profile/presentation/pages/user_data_page.dart';
import '../../../vehicles/presentation/pages/my_vehicles.dart';

const int _clientUserTypeId = 1;
const int _driverUserTypeId = 2;

class HomeDrawer extends StatelessWidget {
  final int? userId;
  final int? userTypeId;

  const HomeDrawer({
    super.key,
    this.userId,
    this.userTypeId,
  });

  @override
  Widget build(BuildContext context) {
    final int? resolvedUserTypeId =
        userTypeId ?? MyselfService().currentUserTypeId;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: FretColors.loginFooterLink,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: FretColors.white,
                    child: Icon(
                      Icons.person,
                      color: FretColors.loginFooterLink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DrawerUserName(userId: userId),
                  const SizedBox(height: 2),
                  const Text(
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
            if (resolvedUserTypeId == _driverUserTypeId) ...[
              _DrawerItem(
                icon: Icons.inbox_outlined,
                label: 'Ofertas de corrida',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DriverOperationsPage(
                        userId: userId ?? MyselfService().currentUserId,
                      ),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.route_outlined,
                label: 'Minhas corridas',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DriverOperationsPage(
                        userId: userId ?? MyselfService().currentUserId,
                        initialTabIndex: 1,
                      ),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Carteira',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DriverOperationsPage(
                        userId: userId ?? MyselfService().currentUserId,
                        initialTabIndex: 2,
                      ),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.local_shipping_outlined,
                label: 'Veículos',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MyVehiclesPage(
                        userId: userId ?? MyselfService().currentUserId,
                      ),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.article_outlined,
                label: 'Documentos',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MyDocumentsPage(
                        userId: userId ?? MyselfService().currentUserId,
                      ),
                    ),
                  );
                },
              ),
            ] else if (resolvedUserTypeId == _clientUserTypeId) ...[
              _DrawerItem(
                icon: Icons.credit_card_outlined,
                label: 'Métodos de pagamento',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MyPaymentMethodsPage(
                        userId: userId ?? MyselfService().currentUserId,
                      ),
                    ),
                  );
                },
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await MyselfService().logout();
                  if (!context.mounted) {
                    return;
                  }

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
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
  final int? userId;

  const _DrawerUserName({this.userId});

  @override
  State<_DrawerUserName> createState() => _DrawerUserNameState();
}

class _DrawerUserNameState extends State<_DrawerUserName> {
  late final Future<MyselfUserModel> _myselfFuture;

  @override
  void initState() {
    super.initState();
    final MyselfService myselfService = MyselfService();
    final int userId = widget.userId ?? myselfService.currentUserId ?? 5;

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
            fontSize: 18,
            height: 1.15,
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
