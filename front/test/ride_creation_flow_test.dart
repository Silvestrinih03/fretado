import 'package:flutter_test/flutter_test.dart';
import 'package:front/features/shipping_request/presentation/models/freight_address_data.dart';
import 'package:front/features/shipping_request/presentation/models/freight_package_data.dart';
import 'package:front/features/shipping_request/presentation/models/freight_quote_model.dart';
import 'package:front/features/shipping_request/presentation/models/ride_creation_conflict.dart';
import 'package:front/features/shipping_request/presentation/models/ride_creation_payload.dart';

void main() {
  test('creation payload carries expected price and required vehicle type', () {
    final payload = buildRideCreationPayload(
      clientUserId: 7,
      addressData: const FreightAddressData(
        pickupAddress: 'Coleta',
        pickupLatitude: -22.9,
        pickupLongitude: -47.0,
        deliveryAddress: 'Entrega',
        deliveryLatitude: -23.0,
        deliveryLongitude: -46.9,
      ),
      packageData: const FreightPackageData(
        widthCm: 10,
        heightCm: 20,
        lengthCm: 30,
        weightKg: 18,
      ),
      quote: FreightQuoteModel.fromJson(_quoteJson()),
    );

    expect(payload['client_user_id'], 7);
    expect(payload['expected_total_price'], '25.56');
    expect(payload['expected_vehicle_type_id'], 3);
    expect(payload['package_weight'], '18.00');
  });

  test('distinguishes updated quote from unavailable driver conflicts', () {
    final quoteChanged = RideCreationConflict.fromResponse(
      statusCode: 409,
      data: <String, dynamic>{
        'detail': <String, dynamic>{
          'message': 'Cotação alterada',
          'quote': _quoteJson(),
        },
      },
    );
    final noDriver = RideCreationConflict.fromResponse(
      statusCode: 409,
      data: const <String, dynamic>{
        'detail': 'Nenhum motorista disponível para esta corrida.',
      },
    );

    expect(quoteChanged.type, RideCreationConflictType.quoteChanged);
    expect(quoteChanged.quote?['required_vehicle_type_id'], 3);
    expect(noDriver.type, RideCreationConflictType.noDriver);
    expect(noDriver.quote, isNull);
  });
}

Map<String, dynamic> _quoteJson() => <String, dynamic>{
  'required_vehicle_type_id': 3,
  'required_vehicle_type_name': 'hatch',
  'distance_km': 12,
  'estimated_time_minutes': 25,
  'delivery_classification': 'pequena',
  'package_volume_cm3': 6000,
  'package_volume_m3': 0.006,
  'total_price': 25.56,
  'pricing': <String, dynamic>{
    'fuel_cost': 5,
    'operational_cost': 3,
    'driver_margin_value': 10,
    'app_fee_value': 5,
    'driver_net_value': 20.56,
  },
  'route': <String, dynamic>{'geometry': <dynamic>[]},
};
