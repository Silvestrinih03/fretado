CREATE TABLE driver_earnings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_user_id BIGINT NOT NULL,
    ride_id BIGINT NOT NULL UNIQUE,
    gross_value DECIMAL(10,2) NOT NULL, -- Valor total da corrida
    app_fee_value DECIMAL(10,2) NOT NULL, -- Valor da taxa do aplicativo
    net_value DECIMAL(10,2) NOT NULL, -- Valor líquido para o motorista
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_driver_earnings_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id),

    CONSTRAINT fk_driver_earnings_ride
        FOREIGN KEY (ride_id) REFERENCES rides(id)
);