CREATE TABLE ride_offer_status (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE ride_offers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    ride_id BIGINT NOT NULL,
    driver_user_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,

    expires_at TIMESTAMP WITH TIME ZONE,
    attempt_order BIGINT NOT NULL DEFAULT 1,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ride_offers_ride
        FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ride_offers_driver
        FOREIGN KEY (driver_user_id)
        REFERENCES users(id),

    CONSTRAINT fk_ride_offers_status
        FOREIGN KEY (status_id)
        REFERENCES ride_offer_status(id),

    CONSTRAINT chk_ride_offer_attempt_order
        CHECK (attempt_order > 0)
);

CREATE INDEX idx_ride_offers_ride_status
ON ride_offers(ride_id, status_id);

CREATE INDEX idx_ride_offers_driver
ON ride_offers(driver_user_id);

CREATE INDEX idx_ride_offers_expires_at
ON ride_offers(expires_at);

CREATE INDEX idx_rides_waiting_dispatch
ON rides(status_id, driver_user_id, created_at);

CREATE UNIQUE INDEX uq_one_pending_offer_per_ride
ON ride_offers(ride_id)
WHERE status_id = 1;