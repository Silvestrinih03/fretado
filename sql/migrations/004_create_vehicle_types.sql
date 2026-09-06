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
        CHECK (
            default_consumption_km_l IS NULL
            OR default_consumption_km_l > 0
        ),

    CONSTRAINT chk_vehicle_type_default_load_capacity
        CHECK (
            default_load_capacity_kg IS NULL
            OR default_load_capacity_kg > 0
        ),

    CONSTRAINT chk_vehicle_type_default_cargo_width
        CHECK (
            default_cargo_width_cm IS NULL
            OR default_cargo_width_cm > 0
        ),

    CONSTRAINT chk_vehicle_type_default_cargo_height
        CHECK (
            default_cargo_height_cm IS NULL
            OR default_cargo_height_cm > 0
        ),

    CONSTRAINT chk_vehicle_type_default_cargo_length
        CHECK (
            default_cargo_length_cm IS NULL
            OR default_cargo_length_cm > 0
        ),

    CONSTRAINT chk_vehicle_type_operational_cost
        CHECK (
            operational_cost_per_km IS NULL
            OR operational_cost_per_km >= 0
        )
);