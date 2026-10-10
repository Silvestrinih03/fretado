CREATE TABLE ride_driver_reassignments (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    kind VARCHAR(30) NOT NULL,
    status VARCHAR(40) NOT NULL,
    reason VARCHAR(500) NOT NULL,
    outgoing_driver_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    incoming_driver_user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT,
    outgoing_offer_id BIGINT NOT NULL REFERENCES ride_offers(id) ON DELETE RESTRICT,
    handoff_address VARCHAR(255),
    handoff_latitude NUMERIC(9,6),
    handoff_longitude NUMERIC(9,6),
    handoff_accuracy NUMERIC(8,2),
    location_recorded_at TIMESTAMP WITH TIME ZONE,
    outgoing_distance_km NUMERIC(10,3),
    incoming_distance_km NUMERIC(10,3),
    outgoing_gross_value NUMERIC(10,2),
    outgoing_app_fee_value NUMERIC(10,2),
    outgoing_net_value NUMERIC(10,2),
    incoming_gross_value NUMERIC(10,2),
    incoming_app_fee_value NUMERIC(10,2),
    incoming_net_value NUMERIC(10,2),
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_driver_reassignment_kind CHECK (kind IN ('pre_pickup_withdrawal', 'delivery_transfer')),
    CONSTRAINT chk_driver_reassignment_status CHECK (status IN ('searching', 'awaiting_replacement', 'awaiting_handoff', 'replacement_unavailable', 'completed', 'cancelled')),
    CONSTRAINT chk_driver_reassignment_reason_length CHECK (char_length(trim(reason)) BETWEEN 10 AND 500),
    CONSTRAINT chk_driver_reassignment_coordinates CHECK (
        (handoff_latitude IS NULL AND handoff_longitude IS NULL)
        OR (handoff_latitude BETWEEN -90 AND 90 AND handoff_longitude BETWEEN -180 AND 180)
    )
);

CREATE UNIQUE INDEX uq_one_delivery_transfer_per_ride
ON ride_driver_reassignments (ride_id)
WHERE kind = 'delivery_transfer';

CREATE UNIQUE INDEX uq_one_active_driver_reassignment
ON ride_driver_reassignments (ride_id)
WHERE status NOT IN ('completed', 'cancelled');

CREATE INDEX idx_driver_reassignments_participants
ON ride_driver_reassignments (outgoing_driver_user_id, incoming_driver_user_id, updated_at DESC);

ALTER TABLE ride_offers
    ADD COLUMN purpose VARCHAR(30) NOT NULL DEFAULT 'standard',
    ADD COLUMN reassignment_id BIGINT REFERENCES ride_driver_reassignments(id) ON DELETE CASCADE,
    ADD CONSTRAINT chk_ride_offer_purpose CHECK (purpose IN ('standard', 'cargo_transfer'));

CREATE INDEX idx_ride_offers_reassignment ON ride_offers (reassignment_id);

CREATE TABLE ride_driver_reassignment_events (
    id BIGSERIAL PRIMARY KEY,
    reassignment_id BIGINT NOT NULL REFERENCES ride_driver_reassignments(id) ON DELETE CASCADE,
    actor_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(60) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_driver_reassignment_events
ON ride_driver_reassignment_events (reassignment_id, created_at, id);

ALTER TABLE driver_earnings DROP CONSTRAINT IF EXISTS driver_earnings_ride_id_key;
CREATE UNIQUE INDEX uq_driver_earnings_ride_driver
ON driver_earnings (ride_id, driver_user_id);

ALTER TABLE driver_earnings DROP CONSTRAINT chk_driver_earnings_type;
ALTER TABLE driver_earnings ADD CONSTRAINT chk_driver_earnings_type CHECK (
    earning_type IN ('ride_completion', 'cancellation_fee', 'cancellation_return', 'ride_transfer_segment')
);
