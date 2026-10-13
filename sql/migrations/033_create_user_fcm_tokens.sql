CREATE TABLE user_fcm_tokens (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    platform VARCHAR(20) NOT NULL DEFAULT 'android',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_user_fcm_tokens_platform CHECK (platform = 'android'),
    CONSTRAINT chk_user_fcm_tokens_token CHECK (
        char_length(trim(token)) BETWEEN 20 AND 4096
    )
);

CREATE INDEX idx_user_fcm_tokens_user_id
ON user_fcm_tokens (user_id);
