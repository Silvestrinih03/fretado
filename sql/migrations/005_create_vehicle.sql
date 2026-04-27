CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type_id BIGINT NOT NULL REFERENCES vehicle_types(id) ON DELETE RESTRICT,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year SMALLINT NOT NULL,
    color VARCHAR(50),
    plate VARCHAR(10) NOT NULL UNIQUE,
    load_capacity_kg INTEGER NOT NULL,
    width_cm INTEGER,
    height_cm INTEGER,
    length_cm INTEGER,
    status BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_vehicle_year CHECK (year >= 1950 AND year <= 2100),
    CONSTRAINT chk_load_capacity CHECK (load_capacity_kg > 0),
    CONSTRAINT chk_width CHECK (width_cm IS NULL OR width_cm > 0),
    CONSTRAINT chk_height CHECK (height_cm IS NULL OR height_cm > 0),
    CONSTRAINT chk_length CHECK (length_cm IS NULL OR length_cm > 0),
    CONSTRAINT chk_plate_format CHECK (plate ~ '^[A-Z]{3}[0-9][A-Z][0-9]{2}$')
);