import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'shipping_resume_page.dart';

class FillInPackageDetailsPage extends StatefulWidget {
  const FillInPackageDetailsPage({super.key});

  @override
  State<FillInPackageDetailsPage> createState() =>
      _FillInPackageDetailsPageState();
}

class _FillInPackageDetailsPageState extends State<FillInPackageDetailsPage> {
  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _fieldBackground = Color(0xFFE4E4E6);
  static const Color _mutedText = Color(0xFF3F4050);
  static const Color _hintText = Color(0xFFBEC0D0);
  static const Color _orange = Color(0xFF9F3F00);

  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _lengthController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _FreightRequestHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 30, 10, 34),
                children: [
                  const Text(
                    'ETAPA 2 DE 4',
                    style: TextStyle(
                      color: _orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Detalhes da Carga',
                    style: TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Insira as medidas exatas para um cálculo\npreciso do seu frete.',
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _PackageDetailsCard(
                    widthController: _widthController,
                    heightController: _heightController,
                    lengthController: _lengthController,
                    weightController: _weightController,
                  ),
                ],
              ),
            ),
            const _BottomCalculateBar(),
          ],
        ),
      ),
    );
  }
}

class _FreightRequestHeader extends StatelessWidget {
  const _FreightRequestHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 47,
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9EAF0))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _FillInPackageDetailsPageState._primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Solicitação de Frete',
            style: TextStyle(
              color: _FillInPackageDetailsPageState._primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageDetailsCard extends StatelessWidget {
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController lengthController;
  final TextEditingController weightController;

  const _PackageDetailsCard({
    required this.widthController,
    required this.heightController,
    required this.lengthController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          _PackageMetricField(
            label: 'Largura',
            controller: widthController,
            icon: Icons.swap_horiz_rounded,
            unit: 'cm',
          ),
          const SizedBox(height: 22),
          _PackageMetricField(
            label: 'Altura',
            controller: heightController,
            icon: Icons.height_rounded,
            unit: 'cm',
          ),
          const SizedBox(height: 22),
          _PackageMetricField(
            label: 'Comprimento',
            controller: lengthController,
            icon: Icons.straighten_rounded,
            unit: 'cm',
          ),
          const SizedBox(height: 22),
          _PackageMetricField(
            label: 'Peso Estimado',
            controller: weightController,
            icon: Icons.shopping_bag,
            iconColor: _FillInPackageDetailsPageState._primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _PackageMetricField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? unit;
  final Color iconColor;

  const _PackageMetricField({
    required this.label,
    required this.controller,
    required this.icon,
    this.unit,
    this.iconColor = const Color(0xFF737382),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FretColors.neutral900,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 37,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: FretColors.neutral800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _FillInPackageDetailsPageState._fieldBackground,
              hintText: '0.00',
              hintStyle: const TextStyle(
                color: _FillInPackageDetailsPageState._hintText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: iconColor, size: 18),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 37,
              ),
              suffixIcon: _FieldUnitSuffix(unit: unit),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 52,
                minHeight: 37,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 9,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldUnitSuffix extends StatelessWidget {
  final String? unit;

  const _FieldUnitSuffix({this.unit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.unfold_more_rounded,
            color: Color(0xFF8E90A1),
            size: 14,
          ),
          if (unit != null) ...[
            const SizedBox(width: 6),
            Text(
              unit!,
              style: const TextStyle(
                color: Color(0xFF565867),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomCalculateBar extends StatelessWidget {
  const _BottomCalculateBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 12, 9, 10),
      color: FretColors.white,
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ShippingResumePage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _FillInPackageDetailsPageState._primaryBlue,
            foregroundColor: FretColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Calcular Valor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.calculate_outlined, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
