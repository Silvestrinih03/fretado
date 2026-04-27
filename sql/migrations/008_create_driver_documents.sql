CREATE TABLE driver_documents (
    id bigint generated always as identity primary key,
    user_id INT NOT NULL,
    license_number VARCHAR(20) NOT NULL,
    license_category_id INT NOT NULL,
    issue_date DATE NOT NULL,
    expiration_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_driver_documents_user
        FOREIGN KEY (user_id)
        REFERENCES users(id),

    CONSTRAINT fk_driver_documents_license_category
        FOREIGN KEY (license_category_id)
        REFERENCES driver_license_categories(id),

    CONSTRAINT uq_driver_documents_user
        UNIQUE (user_id),

    CONSTRAINT uq_driver_documents_license_number
        UNIQUE (license_number),

    CONSTRAINT chk_driver_documents_dates
        CHECK (expiration_date > issue_date)
);