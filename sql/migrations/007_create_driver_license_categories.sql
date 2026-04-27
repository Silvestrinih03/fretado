CREATE TABLE driver_license_categories (
    id bigint generated always as identity primary key,
    code VARCHAR(3) NOT NULL UNIQUE,
    description VARCHAR(100)
);