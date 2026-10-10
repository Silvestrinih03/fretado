import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../data/ride_rating_repository.dart';
import '../pages/ride_rating_page.dart';

class RideRatingAccessButton extends StatefulWidget {
  final int rideId;
  final bool submitted;
  final bool knownPending;
  final VoidCallback? onChanged;
  final String? label;

  const RideRatingAccessButton({
    super.key,
    required this.rideId,
    this.submitted = false,
    this.knownPending = false,
    this.onChanged,
    this.label,
  });

  @override
  State<RideRatingAccessButton> createState() =>
      _RideRatingAccessButtonState();
}

class _RideRatingAccessButtonState extends State<RideRatingAccessButton> {
  late final HttpService _http;
  late final RideRatingRepository _repository;
  bool _loading = false;
  bool _visible = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _http = HttpService();
    _repository = RideRatingRepository(_http);
    _visible = widget.knownPending || widget.submitted;
    _submitted = widget.submitted;
    if (!widget.knownPending && !widget.submitted) _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final state = await _repository.state(widget.rideId);
      if (!mounted) return;
      setState(() {
        _submitted = state.rating != null;
        _visible = state.eligible || _submitted;
      });
    } catch (_) {
      // O detalhe da corrida continua utilizavel se a consulta falhar.
    } finally {
      _loading = false;
    }
  }

  Future<void> _open(BuildContext context) async {
    if (_submitted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RideRatingPage(rideId: widget.rideId),
      ),
    );
    if (changed == true && mounted) {
      setState(() {
        _submitted = true;
        _visible = true;
      });
      widget.onChanged?.call();
    }
  }

  @override
  void dispose() {
    _http.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return FilledButton.icon(
    onPressed: _submitted ? null : () => _open(context),
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      backgroundColor: FretColors.screenGold,
      foregroundColor: FretColors.screenDark,
      disabledBackgroundColor: FretColors.success100,
      disabledForegroundColor: FretColors.success800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    icon: Icon(
      _submitted ? Icons.check_circle_outline_rounded : Icons.star_outline_rounded,
      size: 18,
    ),
    label: Text(
      _submitted ? 'Avaliação enviada' : widget.label ?? 'Avaliar corrida',
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
    );
  }
}
