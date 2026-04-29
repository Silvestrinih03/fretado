CREATE TABLE wallet_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_user_id BIGINT NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    status_id BIGINT NOT NULL,
    pix_key VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_wallet_transactions_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id),

    CONSTRAINT fk_wallet_transactions_status
        FOREIGN KEY (status_id) REFERENCES wallet_transaction_status(id)
);