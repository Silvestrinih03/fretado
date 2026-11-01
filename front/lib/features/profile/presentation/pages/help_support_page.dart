import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  static const _supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'suporte@freteja.com.br',
  );
  static const _faqs = [
    (
      'Como o valor do frete é calculado?',
      'O valor é calculado automaticamente considerando distância, características da carga, '
          'tipo de veículo necessário, consumo estimado, preço de combustível, custos operacionais, '
          'remuneração do motorista e taxa da plataforma. O preço final é exibido antes da confirmação.',
    ),
    (
      'Posso cancelar uma corrida?',
      'O cancelamento depende do estágio da corrida. As condições e eventuais valores '
          'são apresentados no aplicativo antes da confirmação do cancelamento.',
    ),
    (
      'Como acompanho uma corrida em andamento?',
      'As corridas ativas aparecem na tela inicial e na área de Corridas. '
          'Ali você acompanha o status desde o aceite até a finalização da entrega.',
    ),
    (
      'Sou motorista. Como começo a receber solicitações?',
      'Mantenha sua CNH preenchida e dentro da validade, pelo menos um veículo ativo '
          'e seus dados atualizados. Depois, altere seu status para online e permita '
          'o acesso à localização para receber novas solicitações.',
    ),
  ];
  String _search = '';
  String? _openQuestion = _faqs.first.$1;

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final faqs = _faqs.where(
      (item) =>
          item.$1.toLowerCase().contains(query) ||
          item.$2.toLowerCase().contains(query),
    );
    return FretScreenTheme(
      child: Scaffold(
        backgroundColor: FretColors.screenBackground,
        appBar: const FretSecondaryAppBar(title: 'Ajuda e suporte'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FretColors.screenDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FretIconBox(
                      icon: Icons.help_outline_rounded,
                      size: 42,
                      radius: 13,
                      iconColor: FretColors.screenGold,
                      backgroundColor: FretColors.screenGold.withValues(
                        alpha: .12,
                      ),
                      border: Border.all(
                        color: FretColors.screenGold.withValues(alpha: .22),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Como podemos ajudar?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: FretColors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Encontre respostas rápidas para suas dúvidas.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.55,
                        color: FretColors.white.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => _search = value),
                decoration: const InputDecoration(
                  hintText: 'Buscar uma dúvida',
                  fillColor: FretColors.white,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: FretColors.screenMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dúvidas frequentes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              for (final item in faqs) ...[
                _FaqCard(
                  question: item.$1,
                  answer: item.$2,
                  isOpen: _openQuestion == item.$1,
                  onTap: () => setState(
                    () => _openQuestion = _openQuestion == item.$1
                        ? null
                        : item.$1,
                  ),
                ),
                const SizedBox(height: 9),
              ],
              if (faqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        'Nenhuma resposta encontrada',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tente buscar usando outras palavras.',
                        style: TextStyle(
                          fontSize: 12,
                          color: FretColors.screenMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_supportEmail.isNotEmpty) ...[
                const SizedBox(height: 13),
                const Text(
                  'Ainda precisa de ajuda?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                FretScreenCard(
                  radius: 16,
                  child: Row(
                    children: [
                      const FretIconBox(
                        icon: Icons.mail_outline_rounded,
                        iconColor: FretColors.screenGold,
                        backgroundColor: FretColors.screenDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fale com o suporte',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SelectableText(
                              _supportEmail,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FretColors.screenMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar e-mail',
                        icon: const Icon(
                          Icons.copy_outlined,
                          size: 18,
                          color: FretColors.screenGold,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: _supportEmail),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('E-mail copiado.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  final bool isOpen;
  final VoidCallback onTap;
  const _FaqCard({
    required this.question,
    required this.answer,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: FretColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: isOpen
            ? FretColors.screenGold.withValues(alpha: .38)
            : FretColors.screenBorder,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: isOpen
                      ? FretColors.screenGold
                      : FretColors.screenMuted,
                ),
              ],
            ),
            if (isOpen) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: FretColors.screenBorder),
              ),
              Text(
                answer,
                style: const TextStyle(
                  fontSize: 12,
                  color: FretColors.screenMuted,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
