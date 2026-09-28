CREATE TABLE rides (
    id BIGSERIAL PRIMARY KEY,

    client_user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE RESTRICT,

    driver_user_id BIGINT
        REFERENCES users(id)
        ON DELETE RESTRICT,

    required_vehicle_type_id BIGINT NOT NULL
        REFERENCES vehicle_types(id)
        ON DELETE RESTRICT,

    total_price NUMERIC(10,2) NOT NULL,
    app_fee_value NUMERIC(10,2),

    status_id BIGINT NOT NULL
        REFERENCES ride_status(id)
        ON DELETE RESTRICT,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT chk_rides_total_price
        CHECK (total_price >= 0),

    CONSTRAINT chk_rides_app_fee
        CHECK (
            app_fee_value IS NULL
            OR (
                app_fee_value >= 0
                AND app_fee_value <= total_price
            )
        )
);