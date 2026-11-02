CREATE TABLE mapbox_usage (
    account_id VARCHAR(100) NOT NULL,
    product VARCHAR(30) NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    used_requests BIGINT NOT NULL,
    PRIMARY KEY (account_id, product, period_start),
    CONSTRAINT chk_mapbox_usage_nonnegative CHECK (used_requests >= 0),
    CONSTRAINT chk_mapbox_usage_period CHECK (period_end > period_start),
    CONSTRAINT chk_mapbox_usage_product CHECK (product IN ('directions', 'static_tiles'))
);
