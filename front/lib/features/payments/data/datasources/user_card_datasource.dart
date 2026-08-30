import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/user_card_create_model.dart';
import '../models/user_card_model.dart';

class UserCardDatasource {
  final HttpService _httpService;

  const UserCardDatasource(this._httpService);

  Future<List<UserCardModel>> listCardsByUser(int userId) async {
    try {
      final response = await _httpService.get(Endpoints.cardsByUser(userId));

      final dynamic data = response['data'];
      if (data is! List<dynamic>) {
        return <UserCardModel>[];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(UserCardModel.fromJson)
          .toList();
    } on HttpServiceException catch (e) {
      throw UserCardDatasourceException(e.message, statusCode: e.statusCode);
    }
  }

  Future<UserCardModel> createCard(UserCardCreateModel card) async {
    try {
      final response = await _httpService.post(
        Endpoints.createCard,
        body: card.toJson(),
      );

      return UserCardModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw UserCardDatasourceException(e.message, statusCode: e.statusCode);
    }
  }
}

class UserCardDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const UserCardDatasourceException(this.message, {this.statusCode});

  @override
  String toString() => 'UserCardDatasourceException($statusCode): $message';
}
