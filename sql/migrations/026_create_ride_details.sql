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