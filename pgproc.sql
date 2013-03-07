
create schema test;
create extension "uuid-ossp";

create table test.objects ( id uuid PRIMARY KEY, data text );

create or replace function test.create( data text ) returns uuid as $$
DECLARE 
	_id uuid;
BEGIN
	_id := uuid_generate_v4();
	INSERT INTO test.objects (id, data) values ( _id, data);
	return _id;
END
$$ language plpgsql;

create or replace function test.fun( who text ) returns text as $$
BEGIN
	return 'hello ' || who;
END
$$ language plpgsql;
