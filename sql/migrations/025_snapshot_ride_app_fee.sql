-- Preserve the quoted fee even when pricing policies change before completion.
ALTER TABLE rides ADD COLUMN app_fee_value DECIMAL(10,2);
ALTER TABLE rides ADD CONSTRAINT chk_rides_app_fee
    CHECK (app_fee_value >= 0 AND app_fee_value <= total_price);

-- Only backfill fees that are known. Unsettled legacy rides require reconciliation.
UPDATE rides AS ride
SET app_fee_value = earning.app_fee_value
FROM driver_earnings AS earning
WHERE earning.ride_id = ride.id;
