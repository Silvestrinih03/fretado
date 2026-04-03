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
