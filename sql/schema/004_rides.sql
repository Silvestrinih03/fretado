CREATE TABLE ride_status (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE rides (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    client_user_id BIGINT NOT NULL,
    driver_user_id BIGINT,

    origin_address VARCHAR(255) NOT NULL,
    origin_address_complement VARCHAR(255),
    origin_reference_point VARCHAR(255),

    origin_latitude DECIMAL(9,6) NOT NULL,
    origin_longitude DECIMAL(9,6) NOT NULL,

    destination_address VARCHAR(255) NOT NULL,
    destination_address_complement VARCHAR(255),
    destination_reference_point VARCHAR(255),

    destination_latitude DECIMAL(9,6) NOT NULL,
    destination_longitude DECIMAL(9,6) NOT NULL,

    package_width DECIMAL(10,2) NOT NULL,
    package_height DECIMAL(10,2) NOT NULL,
    package_length DECIMAL(10,2) NOT NULL,
    package_weight DECIMAL(10,2) NOT NULL,

    total_price DECIMAL(10,2) NOT NULL,

    status_id BIGINT NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    cancelled_at TIMESTAMP,

    CONSTRAINT fk_rides_client
        FOREIGN KEY (client_user_id)
        REFERENCES users(id),

    CONSTRAINT fk_rides_driver
        FOREIGN KEY (driver_user_id)
        REFERENCES users(id),

    CONSTRAINT fk_rides_status
        FOREIGN KEY (status_id)
        REFERENCES ride_status(id),

    CONSTRAINT chk_rides_package_width
        CHECK (package_width > 0),

    CONSTRAINT chk_rides_package_height
        CHECK (package_height > 0),

    CONSTRAINT chk_rides_package_length
        CHECK (package_length > 0),

    CONSTRAINT chk_rides_package_weight
        CHECK (package_weight > 0),

    CONSTRAINT chk_rides_total_price
        CHECK (total_price >= 0)
);