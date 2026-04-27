ALTER TABLE vehicles
    ADD COLUMN IF NOT EXISTS brand_code VARCHAR(20),
    ADD COLUMN IF NOT EXISTS model_code VARCHAR(20),
    ADD COLUMN IF NOT EXISTS year_code VARCHAR(20),
    ADD COLUMN IF NOT EXISTS year_label VARCHAR(50);

UPDATE vehicles
SET year_label = year::text
WHERE year_label IS NULL;
