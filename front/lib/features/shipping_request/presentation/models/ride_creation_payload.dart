import 'freight_address_data.dart';
import 'freight_package_data.dart';
import 'freight_quote_model.dart';

Map<String, dynamic> buildRideCreationPayload({
  required int clientUserId,
  required FreightAddressData addressData,
  required FreightPackageData packageData,
  required FreightQuoteModel quote,
}) => <String, dynamic>{
  'client_user_id': clientUserId,
  ...addressData.toRideJson(),
  ...packageData.toQuoteJson(),
  'expected_total_price': quote.totalPrice.toStringAsFixed(2),
  'expected_vehicle_type_id': quote.requiredVehicleTypeId,
};
