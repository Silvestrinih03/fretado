CREATE TABLE driver_locations (
    id BIGSERIAL PRIMARY KEY,

    driver_user_id BIGINT NOT NULL,

    is_online BOOLEAN NOT NULL DEFAULT TRUE,

    latitude NUMERIC(9,6) NOT NULL,
    longitude NUMERIC(9,6) NOT NULL,

    accuracy NUMERIC(8,2),

    location_recorded_at TIMESTAMP WITH TIME ZONE,

    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_driver_locations_driver
        FOREIGN KEY (driver_user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_driver_location_latitude
        CHECK (latitude BETWEEN -90 AND 90),

    CONSTRAINT chk_driver_location_longitude
        CHECK (longitude BETWEEN -180 AND 180)
);

CREATE UNIQUE INDEX uq_driver_locations_driver_user
ON driver_locations(driver_user_id);

CREATE INDEX idx_driver_locations_online_seen
ON driver_locations(is_online, last_seen_at);