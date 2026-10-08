CREATE TABLE cancellation_statuses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE ride_cancellations (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE RESTRICT,
    requested_by_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    previous_ride_status_id BIGINT NOT NULL REFERENCES ride_status(id) ON DELETE RESTRICT,
    status_id BIGINT NOT NULL REFERENCES cancellation_statuses(id) ON DELETE RESTRICT,
    reason VARCHAR(500),
    return_destination_type VARCHAR(20),
    return_address VARCHAR(255),
    return_address_complement VARCHAR(255),
    return_reference_point VARCHAR(255),
    return_latitude NUMERIC(9,6),
    return_longitude NUMERIC(9,6),
    original_destination_address VARCHAR(255),
    original_destination_address_complement VARCHAR(255),
    original_destination_reference_point VARCHAR(255),
    original_destination_latitude NUMERIC(9,6),
    original_destination_longitude NUMERIC(9,6),
    driver_latitude NUMERIC(9,6),
    driver_longitude NUMERIC(9,6),
    driver_location_recorded_at TIMESTAMP WITH TIME ZONE,
    quote_prepared_at TIMESTAMP WITH TIME ZONE,
    traveled_distance_km NUMERIC(10,3),
    return_distance_km NUMERIC(10,3),
    cancellation_charge NUMERIC(10,2) NOT NULL DEFAULT 0,
    driver_compensation NUMERIC(10,2) NOT NULL DEFAULT 0,
    refund_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    additional_charge_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    financial_status VARCHAR(30) NOT NULL DEFAULT 'simulated_completed',
    return_ride_id BIGINT REFERENCES rides(id) ON DELETE RESTRICT,
    return_started_at TIMESTAMP WITH TIME ZONE,
    return_completed_at TIMESTAMP WITH TIME ZONE,
    distance_calculation_source VARCHAR(30),
    driver_confirmed_at TIMESTAMP WITH TIME ZONE,
    driver_acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_ride_cancellation_destination_type
        CHECK (return_destination_type IS NULL OR return_destination_type IN ('pickup', 'other')),
    CONSTRAINT chk_ride_cancellation_financial_status
        CHECK (financial_status = 'simulated_completed'),
    CONSTRAINT chk_ride_cancellation_values
        CHECK (
            cancellation_charge >= 0 AND driver_compensation >= 0
            AND refund_amount >= 0 AND additional_charge_amount >= 0
            AND NOT (refund_amount > 0 AND additional_charge_amount > 0)
        ),
    CONSTRAINT chk_ride_cancellation_return_coordinates
        CHECK (
            (return_latitude IS NULL AND return_longitude IS NULL)
            OR (return_latitude BETWEEN -90 AND 90 AND return_longitude BETWEEN -180 AND 180)
        ),
    CONSTRAINT chk_ride_cancellation_driver_coordinates
        CHECK (
            (driver_latitude IS NULL AND driver_longitude IS NULL)
            OR (driver_latitude BETWEEN -90 AND 90 AND driver_longitude BETWEEN -180 AND 180)
        ),
    CONSTRAINT chk_ride_cancellation_original_destination_coordinates
        CHECK (
            (original_destination_latitude IS NULL AND original_destination_longitude IS NULL)
            OR (
                original_destination_latitude BETWEEN -90 AND 90
                AND original_destination_longitude BETWEEN -180 AND 180
            )
        ),
    CONSTRAINT chk_ride_cancellation_distance_source
        CHECK (
            distance_calculation_source IS NULL
            OR distance_calculation_source = 'mapbox_route'
        )
);

CREATE UNIQUE INDEX uq_ride_cancellations_active
ON ride_cancellations (ride_id)
WHERE resolved_at IS NULL;

CREATE INDEX idx_ride_cancellations_ride_created
ON ride_cancellations (ride_id, created_at DESC, id DESC);

CREATE INDEX idx_ride_cancellations_status
ON ride_cancellations (status_id, created_at);

CREATE UNIQUE INDEX uq_ride_cancellations_return_ride
ON ride_cancellations (return_ride_id)
WHERE return_ride_id IS NOT NULL;

CREATE TABLE ride_cancellation_events (
    id BIGSERIAL PRIMARY KEY,
    cancellation_id BIGINT NOT NULL REFERENCES ride_cancellations(id) ON DELETE CASCADE,
    actor_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(60) NOT NULL,
    previous_status_id BIGINT REFERENCES cancellation_statuses(id) ON DELETE RESTRICT,
    new_status_id BIGINT REFERENCES cancellation_statuses(id) ON DELETE RESTRICT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ride_cancellation_events_cancellation
ON ride_cancellation_events (cancellation_id, created_at, id);
