create or replace function schema_.can_like_playlist(
	p_playlist_id integer,
	p_user_id integer
)
returns boolean
as $$
begin
	return (select exists (
		select 1
		from schema_.playlists p
		where p.id=p_playlist_id
		and (
			p.is_private = false
			or
			exists (
				select 1
				from schema_.playlist_owners po
				where po.playlist_id = p_playlist_id
				and po.user_id = p_user_id
			)
		)
	));
end;
$$
language plpgsql;



create table if not exists artist_roles (
	id integer primary key,
	name text unique
);

create or replace function schema_.check_song_has_artist()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.songs_artists
		where song_id=new.id
	) then
		raise exception 'Song (id=%) must have at least one artist.', new.id;
	end if;
	return new;
end
$$
language plpgsql;

create or replace function schema_.check_song_has_release()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.songs_releases
		where song_id=new.id
		and removed_date is null
	) then
		raise exception 'Song (id=%) must have at least one release.', new.id;
	end if;
	return new;
end
$$
language plpgsql;

create or replace function schema_.check_user_has_streaming_account()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.streaming_accounts
		where user_id=new.id
	) then
		raise exception 'User (id=%) must have a streaming account.', new.id;
	end if;
	return new;
end
$$
language plpgsql;

create or replace function schema_.check_user_has_streaming_account_after_delete()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.streaming_accounts
		where user_id=old.user_id
	) then
		raise exception 'User (id=%) must have at least one streaming account connected.', old.user_id;
	end if;
	return old;
end
$$
language plpgsql;

create or replace function schema_.check_song_has_artist_after_delete()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.songs_artists
		where song_id=old.song_id
	) then
		raise exception 'Song (id=%) must have at least one artist.', old.song_id;
	end if;
	return old;
end
$$
language plpgsql;

create or replace function schema_.check_release_has_artist()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.artists_releases
		where release_id=new.id
	) then
		raise exception 'Release (id=%) must have at least one artist.', new.id;
	end if;
	return new;
end
$$
language plpgsql;

create or replace function schema_.check_release_has_artist_after_delete()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.artists_releases
		where release_id=old.release_id
	) then
		raise exception 'Release (id=%) must have at least one artist.', old.release_id;
	end if;
	return old;
end
$$
language plpgsql;

create or replace function schema_.check_release_has_song()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.songs_releases
		where release_id=new.id
	) then
		raise exception 'Release (id=%) must have at least one song.', new.id;
	end if;
	return new;
end
$$
language plpgsql;

create or replace function schema_.check_release_has_song_after_delete()
returns trigger
as $$
begin
	if not exists (
		select 1
		from schema_.songs_releases
		where release_id=old.release_id
	) then
		raise exception 'Release (id=%) must have at least one song.', old.release_id;
	end if;
	return old;
end
$$
language plpgsql;

create constraint trigger trg_song_must_have_artist
after insert or update on schema_.songs
deferrable initially deferred
for each row execute function schema_.check_song_has_artist();

create constraint trigger trg_song_must_have_artist_after_delete
after delete on schema_.songs_artists
deferrable initially deferred
for each row execute function schema_.check_song_has_artist_after_delete();

create constraint trigger trg_song_must_have_release
after insert or update on schema_.songs
deferrable initially deferred
for each row execute function schema_.check_song_has_release();

create constraint trigger trg_user_must_have_streaming_account
after insert on schema_.users
deferrable initially deferred
for each row execute function schema_.check_user_has_streaming_account();

create constraint trigger trg_user_must_have_streaming_account_after_delete
after delete on schema_.streaming_accounts
deferrable initially deferred
for each row execute function schema_.check_user_has_streaming_account_after_delete();

create constraint trigger trg_release_must_have_artist
after insert on schema_.releases
deferrable initially deferred
for each row execute function schema_.check_release_has_artist();

create constraint trigger trg_release_must_have_artist_after_delete
after delete on schema_.artists_releases
deferrable initially deferred
for each row execute function schema_.check_release_has_artist_after_delete();

create constraint trigger trg_release_must_have_song
after insert on schema_.releases
deferrable initially deferred
for each row execute function schema_.check_release_has_song();

create constraint trigger trg_release_must_have_song_after_delete
after delete on schema_.songs_releases
deferrable initially deferred
for each row execute function schema_.check_release_has_song_after_delete();

create or replace rule rl_private_playlists_must_not_have_public_likes
as on update to schema_.playlists
where old.is_private = false and new.is_private = true
do also
	update schema_.playlist_likes pl
	set date_removed = now()
	where pl.playlist_id=new.id
	and pl.user_id not in (
		select po.user_id
		from schema_.playlist_owners po
		where po.playlist_id=new.id
	)
	and pl.date_removed is null;

create or replace function check_import_request_streams_added()
returns trigger
as $$
begin
	if old.streams_successfully_added > new.streams_successfully_added then
		raise exception 'Streams cannot decrease!';
	end if;
	return new;
end;
$$
language plpgsql;

create trigger trg_import_request_streams_must_not_decrease
before update on schema_.import_requests
for each row execute function check_import_request_streams_added();



