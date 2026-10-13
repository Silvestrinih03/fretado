import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/ride_chat/presentation/pages/ride_chat_page.dart';
import '../../features/rides/presentation/pages/ride_tracking_page.dart';
import '../enums/home_profile.dart';
import '../services/session/session_storage.dart';
import 'app_navigator.dart';

bool openPushNotification(Map<String, dynamic> data) {
  final session = SessionStorage.instance;
  final int? currentUserId = session.currentUserId;
  final int? currentUserTypeId = session.currentUserTypeId;
  final int? recipientUserId = int.tryParse('${data['recipient_user_id'] ?? ''}');
  final navigator = appNavigatorKey.currentState;

  if (currentUserId == null ||
      currentUserTypeId == null ||
      !session.hasValidAccessToken ||
      navigator == null) {
    return false;
  }
  if (recipientUserId == null || recipientUserId != currentUserId) {
    return true;
  }

  final type = '${data['type'] ?? ''}';
  final rideId = int.tryParse('${data['ride_id'] ?? ''}');
  final profile = HomeProfileMapper.fromUserTypeId(currentUserTypeId);

  if (type == 'chat_message' && rideId != null) {
    navigator.push<void>(
      MaterialPageRoute<void>(builder: (_) => RideChatPage(rideId: rideId)),
    );
    return true;
  }

  if ({
        'ride_accepted',
        'driver_en_route',
        'pickup_completed',
        'delivery_completed',
      }.contains(type) &&
      rideId != null) {
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RideTrackingPage(
          rideId: rideId,
          userId: currentUserId,
          vehicleCategory: '',
          profile: profile,
        ),
      ),
    );
    return true;
  }

  if (type == 'ride_offer' || type == 'cancellation_requested') {
    navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(
          profile: HomeProfileEnum.driver,
          userId: currentUserId,
          userTypeId: currentUserTypeId,
        ),
      ),
      (_) => false,
    );
    if (type == 'ride_offer') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        requestDriverOfferRefresh();
      });
    }
    return true;
  }

  return true;
}
