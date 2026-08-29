ALTER TABLE driver_locations
ADD COLUMN accuracy NUMERIC(8,2);

ALTER TABLE driver_locations
ADD COLUMN location_recorded_at TIMESTAMPTZ;