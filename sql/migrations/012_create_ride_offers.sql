CREATE TABLE ride_offers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ride_id BIGINT NOT NULL,
    driver_user_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ride_offers_ride
        FOREIGN KEY (ride_id) REFERENCES rides(id),

    CONSTRAINT fk_ride_offers_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id),

    CONSTRAINT fk_ride_offers_status
        FOREIGN KEY (status_id) REFERENCES ride_offer_status(id)
);