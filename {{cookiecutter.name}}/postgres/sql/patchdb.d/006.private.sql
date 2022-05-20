set search_path = {{cookiecutter.name}};


create or replace function up_private()
returns void as $$
begin
    if not install('private'::varchar, array['public']::varchar[]) then
        return;
    end if;

    create table cohorts (
        id int primary key generated always as identity,
        run_id int not null,
        subject_id int not null,
        description varchar not null,
        at timestamptz not null,
        kind varchar not null,
        constraint predictions_require_a_run
            foreign key (run_id) references runs (id)
            on delete cascade
            on update cascade,
        constraint only_one_kind_at_time_per_subject_per_run
            unique (run_id, subject_id, at)
    );

    create table greenishes (
        id int primary key generated always as identity,
        run_id int not null,
        subject_id int not null,
        normal float not null,
        at timestamptz not null,
        constraint predictions_require_a_run
            foreign key (run_id) references runs (id)
            on delete cascade
            on update cascade,
        constraint only_one_greenish_at_time_per_subject_per_run
            unique (run_id, subject_id, at),
        constraint greenish_is_a_normal
            check ((0.0 <= normal) and (normal <= 1.0))
    );

    create table features (
        id int primary key,
        greenish float not null,
        is_animal boolean not null,
        is_vegetable boolean not null,
        is_mineral boolean not null,
        is_unknown boolean not null,
        constraint features_require_a_prediction
            foreign key (id) references predictions (id)
            on delete cascade
            on update cascade,
        constraint greenish_is_a_normal
            check ((0.0 <= greenish) and (greenish <= 1.0)),
        constraint kind_must_be_one_hot_encoded
            check (
                cast(is_animal as int)
                + cast(is_vegetable as int)
                + cast(is_mineral as int)
                + cast(is_unknown as int)
                = 1
            )
    );
end;
$$
    language plpgsql
    set search_path = {{cookiecutter.name}};


create or replace function down_private()
returns void as $$
begin
    if not uninstall('private'::varchar) then
        return;
    end if;

    drop table features;
    drop table greenishes;
    drop table cohorts;
end;
$$
    language plpgsql
    set search_path = {{cookiecutter.name}};


select up_private();
