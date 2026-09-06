CREATE TABLE driver_license_categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(3) NOT NULL UNIQUE,
    description VARCHAR(100)
);

CREATE TABLE driver_documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    user_id BIGINT NOT NULL,
    license_number VARCHAR(20) NOT NULL,
    license_category_id BIGINT NOT NULL,

    issue_date DATE NOT NULL,
    expiration_date DATE NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_driver_documents_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_driver_documents_license_category
        FOREIGN KEY (license_category_id)
        REFERENCES driver_license_categories(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_driver_documents_user
        UNIQUE (user_id),

    CONSTRAINT uq_driver_documents_license_number
        UNIQUE (license_number),

    CONSTRAINT chk_driver_documents_dates
        CHECK (expiration_date > issue_date)
);