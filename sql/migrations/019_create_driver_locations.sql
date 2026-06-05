CREATE TABLE driver_locations (
    id BIGSERIAL PRIMARY KEY,
    driver_user_id BIGINT NOT NULL REFERENCES users(id),
    latitude NUMERIC(9, 6) NOT NULL,
    longitude NUMERIC(9, 6) NOT NULL,
    is_online BOOLEAN NOT NULL DEFAULT TRUE,
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_driver_locations_driver_user
ON driver_locations(driver_user_id);

CREATE INDEX idx_driver_locations_online_seen
ON driver_locations(is_online, last_seen_at);