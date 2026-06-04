ALTER TABLE ride_offers
ADD COLUMN expires_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE ride_offers
ADD COLUMN attempt_order BIGINT NOT NULL DEFAULT 1;

CREATE INDEX idx_ride_offers_ride_status
ON ride_offers (ride_id, status_id);

CREATE INDEX idx_ride_offers_driver
ON ride_offers (driver_user_id);

CREATE INDEX idx_ride_offers_expires_at
ON ride_offers (expires_at);

CREATE INDEX idx_rides_waiting_dispatch
ON rides (status_id, driver_user_id, created_at);

CREATE UNIQUE INDEX uq_one_pending_offer_per_ride
ON ride_offers (ride_id)
WHERE status_id = 1;
