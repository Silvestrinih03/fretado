import '../../../core/endpoints.dart';
import '../../../core/services/http_service.dart';
import 'models/ride_rating_models.dart';

class RideRatingRepository {
  final HttpService _http;

  const RideRatingRepository(this._http);

  Future<RideRatingStateModel> state(int rideId) async {
    final response = await _http.get(Endpoints.myRideRating(rideId));
    return RideRatingStateModel.fromJson(response);
  }

  Future<RideRatingModel> submit({
    required int rideId,
    required int score,
    required List<String> criteria,
    String? comment,
  }) async {
    final response = await _http.post(
      Endpoints.createRideRating(rideId),
      body: {
        'score': score,
        'criteria': criteria,
        'comment': comment,
      },
    );
    return RideRatingModel.fromJson(response);
  }

  Future<PendingRideRatingsPageModel> pending({int? beforeId}) async {
    final response = await _http.get(
      Endpoints.pendingRideRatings(beforeId: beforeId),
    );
    return PendingRideRatingsPageModel.fromJson(response);
  }
}
