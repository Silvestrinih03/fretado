CREATE INDEX idx_rides_client_history
ON rides (client_user_id, created_at DESC, id DESC);

CREATE INDEX idx_rides_client_status_history
ON rides (client_user_id, status_id, created_at DESC, id DESC);

CREATE INDEX idx_rides_driver_history
ON rides (driver_user_id, created_at DESC, id DESC);

CREATE INDEX idx_rides_driver_status_history
ON rides (driver_user_id, status_id, created_at DESC, id DESC);
