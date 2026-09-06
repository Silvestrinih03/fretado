CREATE TABLE fuel_types (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE vehicle_types (
    id BIGSERIAL PRIMARY KEY,

    type VARCHAR(50) NOT NULL UNIQUE,

    default_fuel_type_id BIGINT,

    default_consumption_km_l NUMERIC(6,2),
    default_load_capacity_kg INTEGER,

    default_cargo_width_cm INTEGER,
    default_cargo_height_cm INTEGER,
    default_cargo_length_cm INTEGER,

    operational_cost_per_km NUMERIC(10,2),

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_vehicle_types_default_fuel_type
        FOREIGN KEY (default_fuel_type_id)
        REFERENCES fuel_types(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_vehicle_type_default_consumption
        CHECK (default_consumption_km_l IS NULL OR default_consumption_km_l > 0),

    CONSTRAINT chk_vehicle_type_default_load_capacity
        CHECK (default_load_capacity_kg IS NULL OR default_load_capacity_kg > 0),

    CONSTRAINT chk_vehicle_type_default_cargo_width
        CHECK (default_cargo_width_cm IS NULL OR default_cargo_width_cm > 0),

    CONSTRAINT chk_vehicle_type_default_cargo_height
        CHECK (default_cargo_height_cm IS NULL OR default_cargo_height_cm > 0),

    CONSTRAINT chk_vehicle_type_default_cargo_length
        CHECK (default_cargo_length_cm IS NULL OR default_cargo_length_cm > 0),

    CONSTRAINT chk_vehicle_type_operational_cost
        CHECK (operational_cost_per_km IS NULL OR operational_cost_per_km >= 0)
);

CREATE TABLE vehicle_models (
    id BIGSERIAL PRIMARY KEY,

    vehicle_type_id BIGINT NOT NULL,
    fuel_type_id BIGINT,

    brand VARCHAR(100) NOT NULL,
    brand_code VARCHAR(20),

    model VARCHAR(150) NOT NULL,
    model_code VARCHAR(20),

    year SMALLINT NOT NULL,
    year_code VARCHAR(20),
    year_label VARCHAR(50),

    load_capacity_kg INTEGER,

    cargo_width_cm INTEGER,
    cargo_height_cm INTEGER,
    cargo_length_cm INTEGER,

    average_consumption_km_l NUMERIC(6,2),

    technical_data_source VARCHAR(100),
    technical_data_status VARCHAR(20) NOT NULL DEFAULT 'missing',

    external_provider VARCHAR(30),
    external_id BIGINT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_vehicle_models_vehicle_type
        FOREIGN KEY (vehicle_type_id)
        REFERENCES vehicle_types(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_vehicle_models_fuel_type
        FOREIGN KEY (fuel_type_id)
        REFERENCES fuel_types(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_vehicle_model_year
        CHECK (year >= 1950 AND year <= 2100),

    CONSTRAINT chk_vehicle_model_load_capacity
        CHECK (load_capacity_kg IS NULL OR load_capacity_kg > 0),

    CONSTRAINT chk_vehicle_model_cargo_width
        CHECK (cargo_width_cm IS NULL OR cargo_width_cm > 0),

    CONSTRAINT chk_vehicle_model_cargo_height
        CHECK (cargo_height_cm IS NULL OR cargo_height_cm > 0),

    CONSTRAINT chk_vehicle_model_cargo_length
        CHECK (cargo_length_cm IS NULL OR cargo_length_cm > 0),

    CONSTRAINT chk_vehicle_model_consumption
        CHECK (
            average_consumption_km_l IS NULL
            OR average_consumption_km_l > 0
        ),

    CONSTRAINT chk_vehicle_model_technical_status
        CHECK (
            technical_data_status IN (
                'verified',
                'estimated',
                'missing'
            )
        )
);

CREATE UNIQUE INDEX uq_vehicle_models_catalog_identification
ON vehicle_models (
    brand_code,
    model_code,
    year_code
)
WHERE
    brand_code IS NOT NULL
    AND model_code IS NOT NULL
    AND year_code IS NOT NULL;

CREATE INDEX idx_vehicle_models_vehicle_type
ON vehicle_models(vehicle_type_id);

CREATE INDEX idx_vehicle_models_fuel_type
ON vehicle_models(fuel_type_id);

CREATE UNIQUE INDEX uq_vehicle_models_external
ON vehicle_models (
    external_provider,
    external_id,
    year
)
WHERE
    external_provider IS NOT NULL
    AND external_id IS NOT NULL;

CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,
    vehicle_model_id BIGINT NOT NULL,

    color VARCHAR(50),
    plate VARCHAR(10) NOT NULL UNIQUE,

    status BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_vehicles_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_vehicles_vehicle_model
        FOREIGN KEY (vehicle_model_id)
        REFERENCES vehicle_models(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_plate_format
        CHECK (
            plate ~ '^[A-Z]{3}[0-9]{4}$'
            OR plate ~ '^[A-Z]{3}[0-9][A-Z][0-9]{2}$'
        )
);

CREATE INDEX idx_vehicles_user
ON vehicles(user_id);

CREATE INDEX idx_vehicles_vehicle_model
ON vehicles(vehicle_model_id);

CREATE INDEX idx_vehicles_status
ON vehicles(status);