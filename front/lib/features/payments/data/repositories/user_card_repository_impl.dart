import '../datasources/user_card_datasource.dart';
import '../models/user_card_create_model.dart';
import '../models/user_card_model.dart';
import 'user_card_repository.dart';

class UserCardRepositoryImpl implements UserCardRepository {
  final UserCardDatasource _datasource;

  const UserCardRepositoryImpl(this._datasource);

  @override
  Future<void> removeCard(int userId, int cardId) async {
    try {
      await _datasource.removeCard(userId, cardId);
    } on UserCardDatasourceException catch (e) {
      throw UserCardRepositoryException(e.message);
    }
  }

  @override
  Future<void> setDefaultCard(int userId, int cardId) async {
    try {
      await _datasource.setDefaultCard(userId, cardId);
    } on UserCardDatasourceException catch (e) {
      throw UserCardRepositoryException(e.message);
    }
  }

  @override
  Future<List<UserCardModel>> listCardsByUser(int userId) async {
    try {
      return await _datasource.listCardsByUser(userId);
    } on UserCardDatasourceException catch (e) {
      throw UserCardRepositoryException(e.message);
    }
  }

  @override
  Future<UserCardModel> createCard(UserCardCreateModel card) async {
    try {
      return await _datasource.createCard(card);
    } on UserCardDatasourceException catch (e) {
      throw UserCardRepositoryException(e.message);
    }
  }
}
