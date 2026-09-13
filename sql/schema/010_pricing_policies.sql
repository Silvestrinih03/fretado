CREATE TABLE pricing_policies (
    id BIGSERIAL PRIMARY KEY,

    driver_margin_percentage NUMERIC(5,4) NOT NULL,
    app_fee_percentage NUMERIC(5,4) NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_pricing_driver_margin
        CHECK (
            driver_margin_percentage >= 0
            AND driver_margin_percentage < 1
        ),

    CONSTRAINT chk_pricing_app_fee
        CHECK (
            app_fee_percentage >= 0
            AND app_fee_percentage < 1
        )
);