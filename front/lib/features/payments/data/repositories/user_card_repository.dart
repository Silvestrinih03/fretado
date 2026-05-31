import '../models/user_card_create_model.dart';
import '../models/user_card_model.dart';

abstract class UserCardRepository {
  Future<List<UserCardModel>> listCardsByUser(int userId);

  Future<UserCardModel> createCard(UserCardCreateModel card);
}

class UserCardRepositoryException implements Exception {
  final String message;

  const UserCardRepositoryException(this.message);

  @override
  String toString() => 'UserCardRepositoryException: $message';
}
