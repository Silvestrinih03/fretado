CREATE TABLE ride_driver_reassignments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    kind VARCHAR(30) NOT NULL,
    status VARCHAR(40) NOT NULL,
    reason VARCHAR(500) NOT NULL,
    outgoing_driver_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    incoming_driver_user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT,
    outgoing_offer_id BIGINT NOT NULL REFERENCES ride_offers(id) ON DELETE RESTRICT,
    handoff_address VARCHAR(255),
    handoff_latitude DECIMAL(9,6),
    handoff_longitude DECIMAL(9,6),
    handoff_accuracy DECIMAL(8,2),
    location_recorded_at TIMESTAMP WITH TIME ZONE,
    outgoing_distance_km DECIMAL(10,3),
    incoming_distance_km DECIMAL(10,3),
    outgoing_gross_value DECIMAL(10,2),
    outgoing_app_fee_value DECIMAL(10,2),
    outgoing_net_value DECIMAL(10,2),
    incoming_gross_value DECIMAL(10,2),
    incoming_app_fee_value DECIMAL(10,2),
    incoming_net_value DECIMAL(10,2),
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_driver_reassignment_kind
        CHECK (kind IN ('pre_pickup_withdrawal', 'delivery_transfer')),
    CONSTRAINT chk_driver_reassignment_status
        CHECK (status IN (
            'searching', 'awaiting_replacement', 'awaiting_handoff',
            'replacement_unavailable', 'completed', 'cancelled'
        )),
    CONSTRAINT chk_driver_reassignment_reason_length
        CHECK (char_length(trim(reason)) BETWEEN 10 AND 500),
    CONSTRAINT chk_driver_reassignment_coordinates CHECK (
        (handoff_latitude IS NULL AND handoff_longitude IS NULL)
        OR (
            handoff_latitude BETWEEN -90 AND 90
            AND handoff_longitude BETWEEN -180 AND 180
        )
    )
);

CREATE UNIQUE INDEX uq_active_driver_reassignment_per_ride
ON ride_driver_reassignments (ride_id)
WHERE status IN (
    'searching', 'awaiting_replacement', 'awaiting_handoff',
    'replacement_unavailable'
);

CREATE UNIQUE INDEX uq_delivery_transfer_per_ride
ON ride_driver_reassignments (ride_id)
WHERE kind = 'delivery_transfer';

CREATE INDEX idx_driver_reassignments_outgoing
ON ride_driver_reassignments (outgoing_driver_user_id, status);

CREATE INDEX idx_driver_reassignments_incoming
ON ride_driver_reassignments (incoming_driver_user_id, status);

CREATE TABLE ride_driver_reassignment_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reassignment_id BIGINT NOT NULL
        REFERENCES ride_driver_reassignments(id) ON DELETE CASCADE,
    actor_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(60) NOT NULL,
    event_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_driver_reassignment_events_timeline
ON ride_driver_reassignment_events (reassignment_id, created_at, id);

ALTER TABLE ride_offers
    ADD COLUMN reassignment_id BIGINT,
    ADD CONSTRAINT fk_ride_offers_reassignment
        FOREIGN KEY (reassignment_id)
        REFERENCES ride_driver_reassignments(id)
        ON DELETE CASCADE;

CREATE INDEX idx_ride_offers_reassignment
ON ride_offers (reassignment_id);
