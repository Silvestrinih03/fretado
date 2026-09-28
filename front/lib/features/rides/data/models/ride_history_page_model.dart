import '../../../driver_operations/data/models/driver_operation_models.dart';

enum RideHistoryStatusGroup {
  all('all'),
  pending('pending'),
  completed('completed'),
  interrupted('interrupted');

  final String apiValue;

  const RideHistoryStatusGroup(this.apiValue);
}

class RideHistoryPageModel {
  final List<DriverRideModel> items;
  final String? nextCursor;
  final bool hasMore;

  const RideHistoryPageModel({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  factory RideHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'];
    final items = rawItems is List<dynamic>
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(DriverRideModel.fromJson)
              .toList()
        : <DriverRideModel>[];
    final dynamic rawCursor = json['next_cursor'];

    return RideHistoryPageModel(
      items: items,
      nextCursor: rawCursor is String && rawCursor.isNotEmpty
          ? rawCursor
          : null,
      hasMore: json['has_more'] == true,
    );
  }
}
