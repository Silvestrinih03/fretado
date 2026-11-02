BEGIN;
ALTER TABLE ride_details
    ADD COLUMN IF NOT EXISTS origin_address_number VARCHAR(20),
    ADD COLUMN IF NOT EXISTS destination_address_number VARCHAR(20),
    ADD COLUMN IF NOT EXISTS origin_address_source VARCHAR(255),
    ADD COLUMN IF NOT EXISTS destination_address_source VARCHAR(255);
COMMIT;
