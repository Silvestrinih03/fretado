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

-- TABLE: driver_license_categories
CREATE TABLE driver_license_categories (
    id bigint generated always as identity primary key,
    code VARCHAR(3) NOT NULL UNIQUE,
    description VARCHAR(100)
);

-- TABLE: driver_documents
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

-- TABLE: ride_status
CREATE TABLE ride_status (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL UNIQUE
);

-- TABLE: rides
CREATE TABLE rides (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_user_id BIGINT NOT NULL,
    driver_user_id BIGINT,
    origin_latitude DECIMAL(9,6) NOT NULL,
    origin_longitude DECIMAL(9,6) NOT NULL,
    destination_latitude DECIMAL(9,6) NOT NULL,
    destination_longitude DECIMAL(9,6) NOT NULL,
    package_width DECIMAL(10,2) NOT NULL,
    package_height DECIMAL(10,2) NOT NULL,
    package_length DECIMAL(10,2) NOT NULL,
    package_weight DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP NULL,
    finished_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,

    CONSTRAINT fk_rides_client
        FOREIGN KEY (client_user_id) REFERENCES users(id),

    CONSTRAINT fk_rides_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id),

    CONSTRAINT fk_rides_status
        FOREIGN KEY (status_id) REFERENCES ride_status(id)
);

-- TABLE: ride_offer_status
CREATE TABLE ride_offer_status (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL UNIQUE
);

-- TABLE: ride_offers
CREATE TABLE ride_offers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ride_id BIGINT NOT NULL,
    driver_user_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ride_offers_ride
        FOREIGN KEY (ride_id) REFERENCES rides(id),

    CONSTRAINT fk_ride_offers_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id),

    CONSTRAINT fk_ride_offers_status
        FOREIGN KEY (status_id) REFERENCES ride_offer_status(id)
);

-- TABLE: driver_wallets
CREATE TABLE driver_wallets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_user_id BIGINT NOT NULL UNIQUE,
    available_balance DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_driver_wallets_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id)
);

-- TABLE: driver_earnings
CREATE TABLE driver_earnings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_user_id BIGINT NOT NULL,
    ride_id BIGINT NOT NULL UNIQUE,
    gross_value DECIMAL(10,2) NOT NULL, -- Valor total da corrida
    app_fee_value DECIMAL(10,2) NOT NULL, -- Valor da taxa do aplicativo
    net_value DECIMAL(10,2) NOT NULL, -- Valor líquido para o motorista
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_driver_earnings_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id),

    CONSTRAINT fk_driver_earnings_ride
        FOREIGN KEY (ride_id) REFERENCES rides(id)
);

-- TABLE: wallet_transaction_status
CREATE TABLE wallet_transaction_status (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status VARCHAR(50) NOT NULL UNIQUE
);

-- TABLE: wallet_transactions
CREATE TABLE wallet_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_user_id BIGINT NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    status_id BIGINT NOT NULL,
    pix_key VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_wallet_transactions_driver
        FOREIGN KEY (driver_user_id) REFERENCES users(id),

    CONSTRAINT fk_wallet_transactions_status
        FOREIGN KEY (status_id) REFERENCES wallet_transaction_status(id)
);

-- SEEDs
INSERT INTO user_types (type) VALUES ('client'), ('driver');

INSERT INTO vehicle_types (type) VALUES
('moto'),
('hatch'),
('sedan'),
('pickup'),
('van'),
('utilitário'),
('caminhão');

INSERT INTO driver_license_categories (code, description) VALUES
('A', 'Motocicleta'),
('B', 'Automóvel'),
('C', 'Veículo de carga'),
('D', 'Transporte de passageiros'),
('E', 'Veículos com unidade acoplada');

INSERT INTO ride_status (status) VALUES
('AGUARDANDO_ACEITE'),
('AGUARDANDO_INICIO'),
('A_CAMINHO_COLETA'),
('A_CAMINHO_ENTREGA'),
('FINALIZADA'),
('CANCELADA');

INSERT INTO ride_offer_status (status) VALUES
('PENDENTE'),
('ACEITA'),
('RECUSADA'),
('EXPIRADA');

INSERT INTO wallet_transaction_status (status) VALUES
('PROCESSANDO'),
('FINALIZADO'),
('FALHA'),
('CANCELADO');