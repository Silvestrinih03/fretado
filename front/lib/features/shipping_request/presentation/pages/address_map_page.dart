import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import 'fill_in_package_details_page.dart';

class AddressMapPage extends StatelessWidget {
  const AddressMapPage({super.key});

  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _originOrange = Color(0xFF9F3F00);
  static const Color _inputBackground = Color(0xFFE8E8EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9D8DA),
      body: SafeArea(
        child: Column(
          children: [
            const _RequestHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double markerSize = math.min(
                    48,
                    constraints.maxWidth * 0.13,
                  );
                  final double markerTop = constraints.maxHeight * 0.41;

                  return Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _MapPainter()),
                      ),
                      const Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: _AddressRouteCard(),
                      ),
                      Positioned(
                        top: markerTop,
                        left: (constraints.maxWidth - markerSize) / 2,
                        child: _MapMarker(size: markerSize),
                      ),
                      const Positioned(
                        right: 15,
                        bottom: 86,
                        child: _LocateButton(),
                      ),
                      const Positioned(
                        left: 14,
                        right: 14,
                        bottom: 20,
                        child: _ContinueButton(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      color: const Color(0xFFF7FAFB),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: FretColors.black,
                size: 28,
              ),
            ),
          ),
          const Text(
            'Solicitar Frete',
            style: TextStyle(
              color: FretColors.black,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRouteCard extends StatelessWidget {
  const _AddressRouteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 30, 15, 15),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 72,
            child: _RouteIcons(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              children: const [
                _RouteAddressField(
                  label: 'Minha Localização Atual',
                  textColor: FretColors.black,
                ),
                SizedBox(height: 15),
                _RouteAddressField(
                  label: 'Local de Entrega',
                  textColor: Color(0xFF3F4050),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteIcons extends StatelessWidget {
  const _RouteIcons();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        Positioned(
          top: 21,
          bottom: 21,
          child: CustomPaint(
            size: Size(1, double.infinity),
            painter: _DottedLinePainter(),
          ),
        ),
        Positioned(
          top: 0,
          child: Icon(
            Icons.gps_fixed_rounded,
            color: AddressMapPage._originOrange,
            size: 18,
          ),
        ),
        Positioned(
          bottom: 0,
          child: Icon(
            Icons.location_on_outlined,
            color: AddressMapPage._primaryBlue,
            size: 19,
          ),
        ),
      ],
    );
  }
}

class _RouteAddressField extends StatelessWidget {
  final String label;
  final Color textColor;

  const _RouteAddressField({
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AddressMapPage._inputBackground,
        borderRadius: BorderRadius.circular(5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final double size;

  const _MapMarker({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AddressMapPage._primaryBlue,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22080A73),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.location_on_outlined,
        color: FretColors.white,
        size: size * 0.54,
      ),
    );
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FretColors.white,
      borderRadius: BorderRadius.circular(11),
      elevation: 0,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(11),
        child: const SizedBox(
          width: 49,
          height: 49,
          child: Icon(
            Icons.gps_fixed_rounded,
            color: AddressMapPage._primaryBlue,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FillInPackageDetailsPage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AddressMapPage._primaryBlue,
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
              'Continuar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 16),
            Icon(Icons.arrow_forward_rounded, size: 30),
          ],
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFE6E6EA)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 4), paint);
      y += 11;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  static const List<Offset> _routePoints = [
    Offset(0.24, 0.08),
    Offset(0.31, 0.18),
    Offset(0.26, 0.27),
    Offset(0.39, 0.33),
    Offset(0.45, 0.45),
    Offset(0.37, 0.55),
    Offset(0.48, 0.64),
    Offset(0.36, 0.76),
    Offset(0.18, 0.72),
    Offset(0.12, 0.90),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFC8DADB),
    );

    _drawStreetGrid(canvas, size);
    _drawRoute(canvas, size);
  }

  void _drawStreetGrid(Canvas canvas, Size size) {
    final Paint minorRoad = Paint()
      ..color = FretColors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final Paint majorRoad = Paint()
      ..color = FretColors.white.withValues(alpha: 0.58)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (double x = -size.width; x < size.width * 1.7; x += 17) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.30, size.height),
        minorRoad,
      );
    }

    for (double y = -size.height * 0.25; y < size.height * 1.2; y += 18) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + size.width * 0.24),
        minorRoad,
      );
    }

    for (double x = -size.width * 0.55; x < size.width; x += 46) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.46, 0),
        minorRoad,
      );
    }

    final Path upperRoad = Path()
      ..moveTo(0, size.height * 0.19)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.25,
        size.width * 0.54,
        size.height * 0.21,
        size.width,
        size.height * 0.30,
      );
    final Path lowerRoad = Path()
      ..moveTo(0, size.height * 0.74)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.61,
        size.width * 0.62,
        size.height * 0.68,
        size.width,
        size.height * 0.56,
      );
    final Path diagonalRoad = Path()
      ..moveTo(size.width * 0.06, size.height)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.72,
        size.width * 0.42,
        size.height * 0.55,
        size.width * 0.56,
        0,
      );

    canvas.drawPath(upperRoad, majorRoad);
    canvas.drawPath(lowerRoad, majorRoad);
    canvas.drawPath(diagonalRoad, majorRoad);
  }

  void _drawRoute(Canvas canvas, Size size) {
    final Paint routePaint = Paint()
      ..color = const Color(0xFF436AC8).withValues(alpha: 0.72)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint dotPaint = Paint()
      ..color = const Color(0xFF4167C4).withValues(alpha: 0.78);

    final Path route = Path();
    for (int i = 0; i < _routePoints.length; i++) {
      final Offset point = Offset(
        _routePoints[i].dx * size.width,
        _routePoints[i].dy * size.height,
      );

      if (i == 0) {
        route.moveTo(point.dx, point.dy);
      } else {
        final Offset previous = Offset(
          _routePoints[i - 1].dx * size.width,
          _routePoints[i - 1].dy * size.height,
        );
        final Offset midpoint = Offset(
          (previous.dx + point.dx) / 2,
          (previous.dy + point.dy) / 2,
        );

        route.quadraticBezierTo(midpoint.dx, midpoint.dy, point.dx, point.dy);
      }

      if (i.isEven) {
        canvas.drawCircle(point, 3, dotPaint);
      }
    }

    canvas.drawPath(route, routePaint);

    final Paint branchPaint = Paint()
      ..color = const Color(0xFF436AC8).withValues(alpha: 0.52)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final List<Path> branches = [
      Path()
        ..moveTo(size.width * 0.38, size.height * 0.34)
        ..quadraticBezierTo(
          size.width * 0.24,
          size.height * 0.35,
          size.width * 0.18,
          size.height * 0.48,
        ),
      Path()
        ..moveTo(size.width * 0.45, size.height * 0.45)
        ..quadraticBezierTo(
          size.width * 0.60,
          size.height * 0.48,
          size.width * 0.56,
          size.height * 0.57,
        ),
      Path()
        ..moveTo(size.width * 0.37, size.height * 0.55)
        ..quadraticBezierTo(
          size.width * 0.30,
          size.height * 0.64,
          size.width * 0.20,
          size.height * 0.62,
        ),
    ];

    for (final Path branch in branches) {
      canvas.drawPath(branch, branchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
