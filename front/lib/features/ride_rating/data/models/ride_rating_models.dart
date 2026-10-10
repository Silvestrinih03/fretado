class RideRatingPartyModel {
  final int id;
  final String fullName;
  final String role;

  const RideRatingPartyModel({
    required this.id,
    required this.fullName,
    required this.role,
  });

  factory RideRatingPartyModel.fromJson(Map<String, dynamic> json) =>
      RideRatingPartyModel(
        id: _int(json['id']),
        fullName: '${json['full_name'] ?? 'Usuário'}',
        role: '${json['role'] ?? ''}',
      );
}

class RideRatingCriterionModel {
  final String key;
  final String label;

  const RideRatingCriterionModel({required this.key, required this.label});

  factory RideRatingCriterionModel.fromJson(Map<String, dynamic> json) =>
      RideRatingCriterionModel(
        key: '${json['key'] ?? ''}',
        label: '${json['label'] ?? ''}',
      );
}

class RideRatingModel {
  final int id;
  final int rideId;
  final int score;
  final List<String> criteria;
  final String? comment;
  final DateTime? createdAt;

  const RideRatingModel({
    required this.id,
    required this.rideId,
    required this.score,
    required this.criteria,
    required this.comment,
    required this.createdAt,
  });

  factory RideRatingModel.fromJson(Map<String, dynamic> json) =>
      RideRatingModel(
        id: _int(json['id']),
        rideId: _int(json['ride_id']),
        score: _int(json['score']),
        criteria: (json['criteria'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(),
        comment: json['comment']?.toString(),
        createdAt: _date(json['created_at']),
      );
}

class RideRatingStateModel {
  final int rideId;
  final bool eligible;
  final String? ineligibleReason;
  final RideRatingPartyModel? reviewee;
  final List<RideRatingCriterionModel> allowedCriteria;
  final RideRatingModel? rating;

  const RideRatingStateModel({
    required this.rideId,
    required this.eligible,
    required this.ineligibleReason,
    required this.reviewee,
    required this.allowedCriteria,
    required this.rating,
  });

  factory RideRatingStateModel.fromJson(Map<String, dynamic> json) =>
      RideRatingStateModel(
        rideId: _int(json['ride_id']),
        eligible: json['eligible'] == true,
        ineligibleReason: json['ineligible_reason']?.toString(),
        reviewee: json['reviewee'] is Map
            ? RideRatingPartyModel.fromJson(
                Map<String, dynamic>.from(json['reviewee'] as Map),
              )
            : null,
        allowedCriteria:
            (json['allowed_criteria'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map(
                  (item) => RideRatingCriterionModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(),
        rating: json['rating'] is Map
            ? RideRatingModel.fromJson(
                Map<String, dynamic>.from(json['rating'] as Map),
              )
            : null,
      );
}

class PendingRideRatingModel {
  final int rideId;
  final int? sourceRideId;
  final RideRatingPartyModel reviewee;

  const PendingRideRatingModel({
    required this.rideId,
    required this.sourceRideId,
    required this.reviewee,
  });

  factory PendingRideRatingModel.fromJson(Map<String, dynamic> json) =>
      PendingRideRatingModel(
        rideId: _int(json['ride_id']),
        sourceRideId: _nullableInt(json['source_ride_id']),
        reviewee: RideRatingPartyModel.fromJson(
          Map<String, dynamic>.from(json['reviewee'] as Map),
        ),
      );
}

class PendingRideRatingsPageModel {
  final List<PendingRideRatingModel> items;
  final int? nextBeforeId;
  final bool hasMore;

  const PendingRideRatingsPageModel({
    required this.items,
    required this.nextBeforeId,
    required this.hasMore,
  });

  factory PendingRideRatingsPageModel.fromJson(Map<String, dynamic> json) =>
      PendingRideRatingsPageModel(
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => PendingRideRatingModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
        nextBeforeId: _nullableInt(json['next_before_id']),
        hasMore: json['has_more'] == true,
      );
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) => value == null ? null : _int(value);
DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();
