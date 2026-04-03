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