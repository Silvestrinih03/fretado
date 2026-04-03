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

-- SEED
insert into user_types (type)
values ('client'), ('driver');