import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../widgets/profile_widgets.dart';

enum _TermsPrivacyTab { terms, privacy }

class TermsPrivacyPage extends StatefulWidget {
  const TermsPrivacyPage({super.key});

  @override
  State<TermsPrivacyPage> createState() => _TermsPrivacyPageState();
}

class _TermsPrivacyPageState extends State<TermsPrivacyPage> {
  static const List<_TermsPrivacySection> _termsSections = [
    _TermsPrivacySection(
      title: 'Uso da plataforma',
      text:
          'O FreteJá conecta clientes que precisam transportar cargas a '
          'motoristas disponíveis. Ao utilizar o aplicativo, o usuário se '
          'compromete a fornecer informações verdadeiras e utilizar a '
          'plataforma de forma responsável.',
    ),
    _TermsPrivacySection(
      title: 'Solicitações e corridas',
      text:
          'Antes da confirmação, o cliente visualiza as informações '
          'disponíveis da solicitação e o valor estimado do frete. O andamento '
          'da corrida segue os status apresentados no aplicativo.',
    ),
    _TermsPrivacySection(
      title: 'Valores e pagamentos',
      text:
          'O preço do frete pode considerar distância, características da '
          'carga, veículo necessário, custos operacionais, combustível e '
          'regras comerciais vigentes. O valor final é apresentado antes da '
          'confirmação.',
    ),
    _TermsPrivacySection(
      title: 'Responsabilidades',
      text:
          'Clientes e motoristas são responsáveis pela veracidade das '
          'informações cadastradas e pelo cumprimento das orientações de '
          'segurança aplicáveis ao transporte realizado.',
    ),
  ];

  static const List<_TermsPrivacySection> _privacySections = [
    _TermsPrivacySection(
      title: 'Dados que utilizamos',
      text:
          'Podemos tratar dados de cadastro, contato, veículos, documentos, '
          'localização e informações relacionadas às corridas para permitir o '
          'funcionamento das funcionalidades do aplicativo.',
    ),
    _TermsPrivacySection(
      title: 'Localização',
      text:
          'Para motoristas, a localização pode ser utilizada enquanto '
          'estiverem online para identificar disponibilidade e apoiar o '
          'funcionamento das solicitações de frete.',
    ),
    _TermsPrivacySection(
      title: 'Finalidade',
      text:
          'Os dados são utilizados para autenticação, execução das corridas, '
          'cálculo e pagamento de fretes, segurança, suporte e melhoria da '
          'experiência no aplicativo.',
    ),
    _TermsPrivacySection(
      title: 'Segurança e controle',
      text:
          'O projeto busca limitar o acesso aos dados às funcionalidades '
          'necessárias. O usuário pode consultar e atualizar dados permitidos '
          'pelas opções disponíveis no aplicativo.',
    ),
  ];

  _TermsPrivacyTab _selectedTab = _TermsPrivacyTab.terms;

  List<_TermsPrivacySection> get _sections =>
      _selectedTab == _TermsPrivacyTab.terms
      ? _termsSections
      : _privacySections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FretColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ProfileHeader(title: 'Termos e privacidade'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  const _IntroductionCard(),
                  const SizedBox(height: 16),
                  _TermsPrivacyTabs(
                    selectedTab: _selectedTab,
                    onSelected: (tab) => setState(() => _selectedTab = tab),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(_sections.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _sections.length - 1 ? 0 : 10,
                      ),
                      child: _SectionCard(
                        number: index + 1,
                        section: _sections[index],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const SizedBox(height: 14),
                  const Text(
                    'Última atualização · Setembro de 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FretColors.screenMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroductionCard extends StatelessWidget {
  const _IntroductionCard();

  @override
  Widget build(BuildContext context) {
    return ProfileSurface(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FretColors.screenDark,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 20,
              color: FretColors.screenGold,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transparência e confiança',
                  style: TextStyle(
                    color: FretColors.screenDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Consulte como a plataforma funciona e como seus dados são '
                  'utilizados.',
                  style: TextStyle(
                    color: FretColors.screenMuted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsPrivacyTabs extends StatelessWidget {
  final _TermsPrivacyTab selectedTab;
  final ValueChanged<_TermsPrivacyTab> onSelected;

  const _TermsPrivacyTabs({
    required this.selectedTab,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEAE5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Termos de uso',
              selected: selectedTab == _TermsPrivacyTab.terms,
              onTap: () => onSelected(_TermsPrivacyTab.terms),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Privacidade',
              selected: selectedTab == _TermsPrivacyTab.privacy,
              onTap: () => onSelected(_TermsPrivacyTab.privacy),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? FretColors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? FretColors.screenDark
                    : FretColors.screenMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int number;
  final _TermsPrivacySection section;

  const _SectionCard({required this.number, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: FretColors.screenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x1FC9A227),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Color(0xFF9A7810),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: FretColors.screenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            section.text,
            style: const TextStyle(
              color: FretColors.screenMuted,
              fontSize: 11.5,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsPrivacySection {
  final String title;
  final String text;

  const _TermsPrivacySection({required this.title, required this.text});
}
