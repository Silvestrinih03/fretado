import 'package:flutter/foundation.dart';

import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/models/user_card_create_model.dart';
import '../../data/models/user_card_model.dart';
import '../../data/repositories/user_card_repository.dart';

class PaymentCardsStore extends ChangeNotifier {
  final UserCardRepository _repository;
  final MyselfService _myselfService;
  final int? _fallbackUserId;

  PaymentCardsStore(
    this._repository,
    this._myselfService, {
    int? fallbackUserId,
  }) : _fallbackUserId = fallbackUserId;

  bool _disposed = false;
  int? updatingCardId;
  String? actionErrorMessage;
  bool get isUpdating => updatingCardId != null;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _saveErrorMessage;
  List<UserCardModel> _cards = <UserCardModel>[];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get saveErrorMessage => _saveErrorMessage;
  List<UserCardModel> get cards => List<UserCardModel>.unmodifiable(_cards);

  Future<void> loadCards() async {
    final userId = _myselfService.currentUserId ?? _fallbackUserId;
    if (userId == null) {
      _loadErrorMessage = 'Usuario logado nao encontrado.';
      _cards = <UserCardModel>[];
      _notify();
      return;
    }

    _setLoading(true);
    _loadErrorMessage = null;

    try {
      _cards = await _repository.listCardsByUser(userId);
    } on UserCardRepositoryException catch (e) {
      _loadErrorMessage = e.message;
      _cards = <UserCardModel>[];
    } catch (_) {
      _loadErrorMessage = 'Nao foi possivel carregar seus cartoes.';
      _cards = <UserCardModel>[];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeCard(int cardId) => _updateCard(cardId, remove: true);
  Future<bool> setDefaultCard(int cardId) => _updateCard(cardId, remove: false);

  Future<bool> _updateCard(int cardId, {required bool remove}) async {
    if (isUpdating) return false;
    final userId = _myselfService.currentUserId ?? _fallbackUserId;
    if (userId == null) {
      actionErrorMessage = 'Usuário logado não encontrado.';
      _notify();
      return false;
    }
    updatingCardId = cardId;
    actionErrorMessage = null;
    _notify();
    try {
      if (remove) {
        await _repository.removeCard(userId, cardId);
      } else {
        await _repository.setDefaultCard(userId, cardId);
      }
      await loadCards();
      return true;
    } on UserCardRepositoryException catch (e) {
      actionErrorMessage = e.message;
      return false;
    } catch (_) {
      actionErrorMessage =
          'Não foi possível atualizar o cartão. Tente novamente.';
      return false;
    } finally {
      updatingCardId = null;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<bool> createCard({
    required String cardholderName,
    required String cardNumber,
    required String expiration,
    required String cvv,
    required bool isDefault,
  }) async {
    final userId = _myselfService.currentUserId ?? _fallbackUserId;
    if (userId == null) {
      _saveErrorMessage = 'Usuario logado nao encontrado.';
      _notify();
      return false;
    }

    final parsedExpiration = _parseExpiration(expiration);
    final cleanedCardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    final cleanedCvv = cvv.replaceAll(RegExp(r'\D'), '');
    final cleanedCardholderName = cardholderName.trim();

    if (cleanedCardNumber.isEmpty ||
        cleanedCardholderName.isEmpty ||
        cleanedCvv.isEmpty ||
        parsedExpiration == null) {
      _saveErrorMessage = 'Preencha todos os dados do cartão.';
      _notify();
      return false;
    }

    _setSaving(true);
    _saveErrorMessage = null;

    try {
      final card = UserCardCreateModel(
        userId: userId,
        cardholderName: cleanedCardholderName,
        cardNumber: cleanedCardNumber,
        expirationMonth: parsedExpiration.month,
        expirationYear: parsedExpiration.year,
        cvv: cleanedCvv,
        isDefault: isDefault,
      );

      await _repository.createCard(card);
      return true;
    } on UserCardRepositoryException catch (e) {
      _saveErrorMessage = e.message;
      return false;
    } catch (_) {
      _saveErrorMessage = 'Nao foi possivel salvar o cartao agora.';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  void clearSaveError() {
    _saveErrorMessage = null;
    _notify();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notify();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    _notify();
  }

  _CardExpiration? _parseExpiration(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 4) {
      return null;
    }

    final month = int.tryParse(digits.substring(0, 2));
    final yearSuffix = int.tryParse(digits.substring(2, 4));
    if (month == null || yearSuffix == null || month < 1 || month > 12) {
      return null;
    }

    return _CardExpiration(month: month, year: 2000 + yearSuffix);
  }
}

class _CardExpiration {
  final int month;
  final int year;

  const _CardExpiration({required this.month, required this.year});
}
