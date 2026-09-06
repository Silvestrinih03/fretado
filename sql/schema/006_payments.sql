CREATE TABLE driver_wallets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    driver_user_id BIGINT NOT NULL UNIQUE,
    available_balance DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_driver_wallets_driver
        FOREIGN KEY (driver_user_id)
        REFERENCES users(id),

    CONSTRAINT chk_driver_wallet_balance
        CHECK (available_balance >= 0)
);

CREATE TABLE driver_earnings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    driver_user_id BIGINT NOT NULL,
    ride_id BIGINT NOT NULL UNIQUE,

    gross_value DECIMAL(10,2) NOT NULL,
    app_fee_value DECIMAL(10,2) NOT NULL,
    net_value DECIMAL(10,2) NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_driver_earnings_driver
        FOREIGN KEY (driver_user_id)
        REFERENCES users(id),

    CONSTRAINT fk_driver_earnings_ride
        FOREIGN KEY (ride_id)
        REFERENCES rides(id),

    CONSTRAINT chk_driver_earnings_values
        CHECK (
            gross_value >= 0
            AND app_fee_value >= 0
            AND net_value >= 0
        )
);