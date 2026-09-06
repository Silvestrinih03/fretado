CREATE TABLE user_cards (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    user_id BIGINT NOT NULL,

    cardholder_name VARCHAR(120) NOT NULL,
    brand VARCHAR(30) NOT NULL,
    last_four VARCHAR(4) NOT NULL,

    expiration_month INTEGER NOT NULL,
    expiration_year INTEGER NOT NULL,

    is_default BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_cards_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_user_cards_last_four
        CHECK (last_four ~ '^[0-9]{4}$'),

    CONSTRAINT chk_user_cards_expiration_month
        CHECK (expiration_month BETWEEN 1 AND 12)
);