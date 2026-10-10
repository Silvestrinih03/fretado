CREATE TABLE ride_conversations (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    ride_offer_id BIGINT NOT NULL REFERENCES ride_offers(id) ON DELETE CASCADE,
    client_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    driver_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ride_conversations_offer UNIQUE (ride_offer_id),
    CONSTRAINT chk_ride_conversations_participants CHECK (client_user_id <> driver_user_id)
);

CREATE INDEX idx_ride_conversations_ride_created
ON ride_conversations (ride_id, created_at DESC, id DESC);

CREATE INDEX idx_ride_conversations_driver
ON ride_conversations (driver_user_id, ride_id);

CREATE TABLE ride_messages (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES ride_conversations(id) ON DELETE CASCADE,
    sender_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    client_message_id VARCHAR(80) NOT NULL,
    content VARCHAR(1000) NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_ride_messages_client_message UNIQUE (conversation_id, client_message_id),
    CONSTRAINT chk_ride_messages_content CHECK (char_length(trim(content)) BETWEEN 1 AND 1000),
    CONSTRAINT chk_ride_messages_read_after_send CHECK (read_at IS NULL OR read_at >= sent_at)
);

CREATE INDEX idx_ride_messages_conversation_id
ON ride_messages (conversation_id, id DESC);

CREATE INDEX idx_ride_messages_unread
ON ride_messages (conversation_id, id)
WHERE read_at IS NULL;
