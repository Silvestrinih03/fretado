CREATE TABLE ride_status (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL UNIQUE
);

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

CREATE INDEX idx_rides_client_history
ON rides (client_user_id, created_at DESC, id DESC);

CREATE INDEX idx_rides_client_status_history
ON rides (client_user_id, status_id, created_at DESC, id DESC);

CREATE INDEX idx_rides_driver_history
ON rides (driver_user_id, created_at DESC, id DESC);

CREATE INDEX idx_rides_driver_status_history
ON rides (driver_user_id, status_id, created_at DESC, id DESC);

CREATE TABLE ride_details (
    id BIGSERIAL PRIMARY KEY,

    ride_id BIGINT NOT NULL UNIQUE
        REFERENCES rides(id)
        ON DELETE CASCADE,

    origin_address VARCHAR(255) NOT NULL,
    origin_address_complement VARCHAR(255),
    origin_reference_point VARCHAR(255),

    origin_latitude NUMERIC(9,6) NOT NULL,
    origin_longitude NUMERIC(9,6) NOT NULL,

    destination_address VARCHAR(255) NOT NULL,
    destination_address_complement VARCHAR(255),
    destination_reference_point VARCHAR(255),

    destination_latitude NUMERIC(9,6) NOT NULL,
    destination_longitude NUMERIC(9,6) NOT NULL,

    package_width NUMERIC(10,2) NOT NULL,
    package_height NUMERIC(10,2) NOT NULL,
    package_length NUMERIC(10,2) NOT NULL,
    package_weight NUMERIC(10,2) NOT NULL,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_ride_details_package_width
        CHECK (package_width > 0),

    CONSTRAINT chk_ride_details_package_height
        CHECK (package_height > 0),

    CONSTRAINT chk_ride_details_package_length
        CHECK (package_length > 0),

    CONSTRAINT chk_ride_details_package_weight
        CHECK (package_weight > 0),

    CONSTRAINT chk_ride_details_origin_latitude
        CHECK (
            origin_latitude >= -90
            AND origin_latitude <= 90
        ),

    CONSTRAINT chk_ride_details_origin_longitude
        CHECK (
            origin_longitude >= -180
            AND origin_longitude <= 180
        ),

    CONSTRAINT chk_ride_details_destination_latitude
        CHECK (
            destination_latitude >= -90
            AND destination_latitude <= 90
        ),

    CONSTRAINT chk_ride_details_destination_longitude
        CHECK (
            destination_longitude >= -180
            AND destination_longitude <= 180
        )
);