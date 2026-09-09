CREATE TABLE fuel_prices (
    id BIGSERIAL PRIMARY KEY,

    fuel_type_id BIGINT NOT NULL,

    state VARCHAR(2) NOT NULL,

    average_price NUMERIC(10,3) NOT NULL,

    reference_start_date DATE NOT NULL,
    reference_end_date DATE NOT NULL,

    source VARCHAR(50) NOT NULL DEFAULT 'ANP',

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_fuel_prices_fuel_type
        FOREIGN KEY (fuel_type_id)
        REFERENCES fuel_types(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_fuel_prices_average_price
        CHECK (average_price > 0),

    CONSTRAINT chk_fuel_prices_reference_dates
        CHECK (reference_end_date >= reference_start_date)
);

CREATE UNIQUE INDEX uq_fuel_prices_period
ON fuel_prices (
    fuel_type_id,
    state,
    reference_start_date,
    reference_end_date
);

CREATE INDEX idx_fuel_prices_lookup
ON fuel_prices (
    fuel_type_id,
    state,
    reference_end_date DESC
);