CREATE TABLE ride_ratings (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    ride_offer_id BIGINT NOT NULL REFERENCES ride_offers(id) ON DELETE RESTRICT,
    reviewer_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    reviewee_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    score SMALLINT NOT NULL,
    criteria VARCHAR(40)[] NOT NULL DEFAULT '{}'::VARCHAR[],
    comment VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ride_ratings_ride_reviewer UNIQUE (ride_id, reviewer_user_id),
    CONSTRAINT chk_ride_ratings_participants CHECK (reviewer_user_id <> reviewee_user_id),
    CONSTRAINT chk_ride_ratings_score CHECK (score BETWEEN 1 AND 5),
    CONSTRAINT chk_ride_ratings_comment CHECK (
        comment IS NULL OR char_length(trim(comment)) BETWEEN 1 AND 500
    ),
    CONSTRAINT chk_ride_ratings_criteria_count CHECK (cardinality(criteria) <= 4),
    CONSTRAINT chk_ride_ratings_criteria_values CHECK (
        criteria <@ ARRAY[
            'punctuality',
            'cargo_care',
            'communication',
            'courtesy',
            'pickup_access',
            'accurate_information'
        ]::VARCHAR[]
    )
);

CREATE INDEX idx_ride_ratings_reviewee_created
ON ride_ratings (reviewee_user_id, created_at DESC, id DESC);

CREATE INDEX idx_ride_ratings_reviewer_created
ON ride_ratings (reviewer_user_id, created_at DESC, id DESC);

CREATE INDEX idx_ride_ratings_offer
ON ride_ratings (ride_offer_id);
