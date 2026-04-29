CREATE TABLE driver_wallets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_user_id BIGINT NOT NULL UNIQUE,
    available_balance DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_driver_wallets_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id)
);