enum RideCreationConflictType { quoteChanged, noDriver, other }

class RideCreationConflict {
  final RideCreationConflictType type;
  final Map<String, dynamic>? quote;

  const RideCreationConflict._(this.type, [this.quote]);

  static RideCreationConflict fromResponse({
    required int? statusCode,
    required Map<String, dynamic>? data,
  }) {
    if (statusCode != 409) {
      return const RideCreationConflict._(RideCreationConflictType.other);
    }

    final detail = data?['detail'];
    final dynamic rawQuote = detail is Map ? detail['quote'] : data?['quote'];
    if (rawQuote is Map) {
      return RideCreationConflict._(
        RideCreationConflictType.quoteChanged,
        Map<String, dynamic>.from(rawQuote),
      );
    }

    return const RideCreationConflict._(RideCreationConflictType.noDriver);
  }
}
