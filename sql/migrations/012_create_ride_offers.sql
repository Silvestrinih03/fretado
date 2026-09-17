CREATE TABLE ride_offers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ride_id BIGINT NOT NULL,
    driver_user_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,

    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ride_offers_ride
        FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ride_offers_driver
        FOREIGN KEY (driver_user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_ride_offers_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_ride_offers_status
        FOREIGN KEY (status_id)
        REFERENCES ride_offer_status(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_ride_offer_expiration
        CHECK (expires_at > created_at)
);

CREATE INDEX idx_ride_offers_ride_status
ON ride_offers (ride_id, status_id);

CREATE INDEX idx_ride_offers_driver
ON ride_offers (driver_user_id);

CREATE INDEX idx_ride_offers_status_expires_at
ON ride_offers (status_id, expires_at);

CREATE UNIQUE INDEX uq_one_pending_offer_per_ride
ON ride_offers (ride_id)
WHERE status_id = 1;

CREATE UNIQUE INDEX uq_one_pending_offer_per_driver
ON ride_offers (driver_user_id)
WHERE status_id = 1;

CREATE UNIQUE INDEX uq_ride_offer_driver
ON ride_offers (ride_id, driver_user_id);