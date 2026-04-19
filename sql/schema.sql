-- TABLE: user_types
create table user_types (
    id bigint generated always as identity primary key,
    type varchar(20) not null unique
);

-- TABLE: users
create table users (
    id bigint generated always as identity primary key,
    cpf varchar(14) not null unique,
    email varchar(255) not null unique,
    password_hash varchar(255) not null,
    user_type_id bigint not null,
    constraint fk_users_user_type
        foreign key (user_type_id)
        references user_types (id)
);

-- TABLE: user_profiles
create table user_profiles (
    id bigint generated always as identity primary key,
    user_id bigint not null unique,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    birth_date date,
    phone varchar(20),
    constraint fk_user_profiles_user
        foreign key (user_id)
        references users (id)
);

-- TABLE: vehicle_types
CREATE TABLE vehicle_types (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL UNIQUE
);

-- TABLE: vehicles
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type_id BIGINT NOT NULL REFERENCES vehicle_types(id) ON DELETE RESTRICT,
    brand_code VARCHAR(20),
    brand VARCHAR(100) NOT NULL,
    model_code VARCHAR(20),
    model VARCHAR(100) NOT NULL,
    year_code VARCHAR(20),
    year SMALLINT NOT NULL,
    year_label VARCHAR(50),
    color VARCHAR(50),
    plate VARCHAR(10) NOT NULL UNIQUE,
    load_capacity_kg INTEGER NOT NULL,
    width_cm INTEGER,
    height_cm INTEGER,
    length_cm INTEGER,
    status BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_vehicle_year CHECK (year >= 1950 AND year <= 2100),
    CONSTRAINT chk_load_capacity CHECK (load_capacity_kg > 0),
    CONSTRAINT chk_width CHECK (width_cm IS NULL OR width_cm > 0),
    CONSTRAINT chk_height CHECK (height_cm IS NULL OR height_cm > 0),
    CONSTRAINT chk_length CHECK (length_cm IS NULL OR length_cm > 0),
    CONSTRAINT chk_plate_format CHECK (plate ~ '^[A-Z]{3}[0-9][A-Z][0-9]{2}$')
);

-- SEED
insert into user_types (type)
values ('client'), ('driver');

INSERT INTO vehicle_types (type) VALUES
('moto'),
('hatch'),
('sedan'),
('pickup'),
('van'),
('utilitário'),
('caminhão');
