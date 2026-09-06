CREATE TABLE vehicle_models (
    id BIGSERIAL PRIMARY KEY,

    vehicle_type_id BIGINT NOT NULL
        REFERENCES vehicle_types(id)
        ON DELETE RESTRICT,

    fuel_type_id BIGINT
        REFERENCES fuel_types(id)
        ON DELETE RESTRICT,

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

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_vehicle_model_year
        CHECK (year >= 1950 AND year <= 2100),

    CONSTRAINT chk_vehicle_model_load_capacity
        CHECK (
            load_capacity_kg IS NULL
            OR load_capacity_kg > 0
        ),

    CONSTRAINT chk_vehicle_model_cargo_width
        CHECK (
            cargo_width_cm IS NULL
            OR cargo_width_cm > 0
        ),

    CONSTRAINT chk_vehicle_model_cargo_height
        CHECK (
            cargo_height_cm IS NULL
            OR cargo_height_cm > 0
        ),

    CONSTRAINT chk_vehicle_model_cargo_length
        CHECK (
            cargo_length_cm IS NULL
            OR cargo_length_cm > 0
        ),

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