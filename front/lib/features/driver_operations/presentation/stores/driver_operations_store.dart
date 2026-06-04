import 'package:flutter/foundation.dart';

import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/models/driver_operation_models.dart';
import '../../data/repositories/driver_operations_repository.dart';

class DriverOperationsStore extends ChangeNotifier {
  final DriverOperationsRepository _repository;
  final MyselfService _myselfService;
  final int? _fallbackUserId;

  DriverOperationsStore(
    this._repository,
    this._myselfService, {
    int? fallbackUserId,
  }) : _fallbackUserId = fallbackUserId;

  bool _isLoading = false;
  bool _isRefreshingWallet = false;
  bool _isWithdrawing = false;
  int? _offerInActionId;
  String? _errorMessage;
  String? _actionMessage;
  DriverWalletModel? _wallet;
  Map<int, DriverRideModel> _offerRides = <int, DriverRideModel>{};
  List<RideOfferModel> _offers = <RideOfferModel>[];
  List<DriverRideModel> _rides = <DriverRideModel>[];
  List<WalletTransactionModel> _transactions = <WalletTransactionModel>[];
  List<DriverEarningModel> _earnings = <DriverEarningModel>[];

  bool get isLoading => _isLoading;
  bool get isRefreshingWallet => _isRefreshingWallet;
  bool get isWithdrawing => _isWithdrawing;
  int? get offerInActionId => _offerInActionId;
  String? get errorMessage => _errorMessage;
  String? get actionMessage => _actionMessage;
  DriverWalletModel? get wallet => _wallet;
  Map<int, DriverRideModel> get offerRides =>
      Map<int, DriverRideModel>.unmodifiable(_offerRides);
  List<RideOfferModel> get offers => List<RideOfferModel>.unmodifiable(_offers);
  List<DriverRideModel> get rides => List<DriverRideModel>.unmodifiable(_rides);
  List<WalletTransactionModel> get transactions =>
      List<WalletTransactionModel>.unmodifiable(_transactions);
  List<DriverEarningModel> get earnings =>
      List<DriverEarningModel>.unmodifiable(_earnings);

  List<RideOfferModel> get pendingOffers =>
      _offers.where((offer) => offer.isPending).toList(growable: false);

  double get availableBalance => _wallet?.availableBalance ?? 0;

  double get totalNetEarnings {
    return _earnings.fold<double>(
      0,
      (total, earning) => total + earning.netValue,
    );
  }

  Future<void> load() async {
    final userId = _resolveUserId();
    if (userId == null) {
      _errorMessage = 'Usuario logado nao encontrado.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _offers = await _repository.listOffersByDriver(userId);
      _rides = await _repository.listRidesByDriver(userId);
      await _loadOfferRideDetails();
      _wallet = await _repository.getWalletByDriver(userId);
      _transactions = await _repository.listTransactionsByDriver(userId);
      _earnings = await _repository.listEarningsByDriver(userId);
    } on DriverOperationsRepositoryException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar a operacao do motorista.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadWallet() async {
    final userId = _resolveUserId();
    if (userId == null) {
      return;
    }

    _isRefreshingWallet = true;
    notifyListeners();

    try {
      _wallet = await _repository.getWalletByDriver(userId);
      _transactions = await _repository.listTransactionsByDriver(userId);
      _earnings = await _repository.listEarningsByDriver(userId);
    } finally {
      _isRefreshingWallet = false;
      notifyListeners();
    }
  }

  Future<bool> acceptOffer(int offerId) async {
    final userId = _resolveUserId();
    if (userId == null) {
      _actionMessage = 'Usuario logado nao encontrado.';
      notifyListeners();
      return false;
    }

    _offerInActionId = offerId;
    _actionMessage = null;
    notifyListeners();

    try {
      await _repository.acceptOffer(offerId);
      _actionMessage = 'Oferta aceita.';
      _offers = await _repository.listOffersByDriver(userId);
      _rides = await _repository.listRidesByDriver(userId);
      await _loadOfferRideDetails();
      return true;
    } on DriverOperationsRepositoryException catch (e) {
      _actionMessage = e.message;
      await _reloadOffersAndRides(userId);
      return false;
    } catch (_) {
      _actionMessage = 'Nao foi possivel aceitar a oferta.';
      await _reloadOffersAndRides(userId);
      return false;
    } finally {
      _offerInActionId = null;
      notifyListeners();
    }
  }

  Future<bool> rejectOffer(int offerId) async {
    final userId = _resolveUserId();
    if (userId == null) {
      _actionMessage = 'Usuario logado nao encontrado.';
      notifyListeners();
      return false;
    }

    _offerInActionId = offerId;
    _actionMessage = null;
    notifyListeners();

    try {
      await _repository.rejectOffer(offerId);
      _actionMessage = 'Oferta recusada.';
      _offers = await _repository.listOffersByDriver(userId);
      await _loadOfferRideDetails();
      return true;
    } on DriverOperationsRepositoryException catch (e) {
      _actionMessage = e.message;
      return false;
    } catch (_) {
      _actionMessage = 'Nao foi possivel recusar a oferta.';
      return false;
    } finally {
      _offerInActionId = null;
      notifyListeners();
    }
  }

  Future<bool> requestWithdraw({
    required String valueText,
    required String pixKey,
  }) async {
    final userId = _resolveUserId();
    if (userId == null) {
      _actionMessage = 'Usuario logado nao encontrado.';
      notifyListeners();
      return false;
    }

    final value = _parseMoney(valueText);
    final cleanedPixKey = pixKey.trim();
    if (value == null || value <= 0 || cleanedPixKey.isEmpty) {
      _actionMessage = 'Informe valor e chave Pix validos.';
      notifyListeners();
      return false;
    }

    if (value > availableBalance) {
      _actionMessage = 'Valor maior que o saldo disponivel.';
      notifyListeners();
      return false;
    }

    _isWithdrawing = true;
    _actionMessage = null;
    notifyListeners();

    try {
      await _repository.requestWithdraw(
        driverUserId: userId,
        request: WalletWithdrawRequestModel(
          value: value,
          pixKey: cleanedPixKey,
        ),
      );
      _actionMessage = 'Saque solicitado.';
      _wallet = await _repository.getWalletByDriver(userId);
      _transactions = await _repository.listTransactionsByDriver(userId);
      return true;
    } on DriverOperationsRepositoryException catch (e) {
      _actionMessage = e.message;
      return false;
    } catch (_) {
      _actionMessage = 'Nao foi possivel solicitar o saque.';
      return false;
    } finally {
      _isWithdrawing = false;
      notifyListeners();
    }
  }

  void clearActionMessage() {
    _actionMessage = null;
    notifyListeners();
  }

  int? _resolveUserId() {
    return _myselfService.currentUserId ?? _fallbackUserId;
  }

  Future<void> _loadOfferRideDetails() async {
    final ridesById = <int, DriverRideModel>{
      for (final ride in _rides) ride.id: ride,
    };

    for (final offer in _offers) {
      if (ridesById.containsKey(offer.rideId)) {
        continue;
      }

      try {
        ridesById[offer.rideId] = await _repository.getRideById(offer.rideId);
      } catch (_) {
        // Offer actions still work even if ride details cannot be loaded.
      }
    }

    _offerRides = ridesById;
  }

  Future<void> _reloadOffersAndRides(int userId) async {
    try {
      _offers = await _repository.listOffersByDriver(userId);
      _rides = await _repository.listRidesByDriver(userId);
      await _loadOfferRideDetails();
    } catch (_) {
      // Keep the original action error visible.
    }
  }

  double? _parseMoney(String value) {
    final cleaned = value
        .trim()
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(cleaned);
  }
}
