create table user_types (
    id bigint generated always as identity primary key,
    type varchar(20) not null unique
);