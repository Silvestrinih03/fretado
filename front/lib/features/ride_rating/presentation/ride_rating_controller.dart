import 'package:flutter/foundation.dart';

import '../data/models/ride_rating_models.dart';
import '../data/ride_rating_repository.dart';

class RideRatingController extends ChangeNotifier {
  final RideRatingRepository repository;
  final int rideId;

  RideRatingController({required this.repository, required this.rideId});

  RideRatingStateModel? state;
  int score = 0;
  final Set<String> criteria = <String>{};
  bool loading = true;
  bool sending = false;
  bool sent = false;
  String? error;

  Future<void> initialize() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      state = await repository.state(rideId);
      sent = state?.rating != null;
    } catch (_) {
      error = 'Não foi possível carregar a avaliação.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectScore(int value) {
    score = value;
    error = null;
    notifyListeners();
  }

  void toggleCriterion(String key) {
    criteria.contains(key) ? criteria.remove(key) : criteria.add(key);
    notifyListeners();
  }

  Future<bool> submit(String comment) async {
    if (score < 1 || sending || state?.eligible != true) return false;
    sending = true;
    error = null;
    notifyListeners();
    try {
      final rating = await repository.submit(
        rideId: rideId,
        score: score,
        criteria: criteria.toList(),
        comment: comment.trim().isEmpty ? null : comment.trim(),
      );
      state = RideRatingStateModel(
        rideId: state!.rideId,
        eligible: false,
        ineligibleReason: 'Avaliação já enviada.',
        reviewee: state!.reviewee,
        allowedCriteria: state!.allowedCriteria,
        rating: rating,
      );
      sent = true;
      return true;
    } catch (exception) {
      error = exception is Exception
          ? 'Não foi possível enviar a avaliação. Tente novamente.'
          : 'Não foi possível enviar a avaliação.';
      return false;
    } finally {
      sending = false;
      notifyListeners();
    }
  }
}
