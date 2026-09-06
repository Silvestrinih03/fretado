import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../widgets/profile_widgets.dart';
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
  late Future<MyselfUserModel> _myselfFuture;

  @override
  void initState() {
    super.initState();
    _myselfService = MyselfService();
    _myselfService.currentUserId = widget.userId;
    _myselfFuture = _myselfService.getMyself(widget.userId);
  }

  @override
  void didUpdateWidget(covariant ClientProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _myselfService.currentUserId = widget.userId;
      _myselfFuture = _myselfService.getMyself(widget.userId);
    }
  }

  Future<void> _reload() async {
    final future = _myselfService.getMyself(widget.userId);
    setState(() { _myselfFuture = future; });
    try { await future; } catch (_) { /* Displayed by FutureBuilder. */ }
  }

  Future<void> _logout() async {
    await _myselfService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _openUserData() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const UserDataPage()));
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FretColors.screenBackground,
    body: SafeArea(child: Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: Align(alignment: Alignment.centerLeft, child: Text('Perfil',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
            color: FretColors.screenDark, letterSpacing: -0.5))),
      ),
      Expanded(child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            FutureBuilder<MyselfUserModel>(
              future: _myselfFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const ProfileSurface(child: SizedBox(height: 144,
                    child: Center(child: CircularProgressIndicator(color: FretColors.screenGold))));
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return ProfileSurface(child: Column(children: [
                    const Text('Não foi possível carregar seu perfil.'),
                    TextButton(onPressed: _reload, child: const Text('Tentar novamente')),
                  ]));
                }
                final user = snapshot.data!;
                return ProfileSurface(radius: 20, padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Row(children: [
                      ProfileAvatar(name: user.fullName),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: FretColors.screenDark)),
                        const SizedBox(height: 2),
                        const Text('Cliente', style: TextStyle(fontSize: 12, color: FretColors.screenMuted)),
                        const SizedBox(height: 6),
                        Text(user.email, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: FretColors.screenGold)),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: FretColors.screenBorder),
                    const SizedBox(height: 16),
                    IntrinsicHeight(child: Row(children: [
                      Expanded(child: _ProfileStatistic(value: '${user.completedRidesCount}', label: 'Corridas realizadas')),
                      const VerticalDivider(width: 1, color: FretColors.screenBorder),
                      // Temporary until membership dates are provided by the API.
                      const Expanded(child: _ProfileStatistic(value: '2026', label: 'Membro desde')),
                    ])),
                  ]));
              },
            ),
            const SizedBox(height: 14),
            _ProfileActionTile(icon: Icons.person_outline_rounded, title: 'Dados pessoais',
              subtitle: 'Nome, e-mail e telefone', onTap: _openUserData),
            const SizedBox(height: 10),
            _ProfileActionTile(icon: Icons.shield_outlined, title: 'Segurança e senha',
              subtitle: 'Alterar senha de acesso', onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ChangePasswordPopup()))),
            const SizedBox(height: 10),
            const _ProfileActionTile(icon: Icons.help_outline_rounded,
              title: 'Ajuda e suporte', subtitle: 'Central de atendimento'),
            const SizedBox(height: 10),
            const _ProfileActionTile(icon: Icons.description_outlined,
              title: 'Termos e privacidade', subtitle: 'Políticas do aplicativo'),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 17),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FretColors.screenMuted,
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: Color(0x1F1A1A1A), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      )),
    ])),
  );
}

class _ProfileStatistic extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStatistic({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: FretColors.screenDark)),
    const SizedBox(height: 2),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: FretColors.screenMuted)),
  ]);
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _ProfileActionTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) => ProfileSurface(
    padding: EdgeInsets.zero,
    child: Material(color: Colors.transparent, child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          ProfileIcon(icon: icon),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FretColors.screenDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: FretColors.screenMuted)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 16, color: FretColors.screenGold),
        ])),
    )),
  );
}
