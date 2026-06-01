--
-- PostgreSQL database dump
--

\restrict Tvz776JbDlg8iDbja9S9QwUvKyezcDiVY7AkI2vccdObbI6fRNF41noRfkyPzDh

-- Dumped from database version 16.13
-- Dumped by pg_dump version 18.3 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


--
-- Name: schema_; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA schema_;


--
-- Name: artist_role_enum; Type: TYPE; Schema: schema_; Owner: -
--

CREATE TYPE schema_.artist_role_enum AS ENUM (
    'primary artist',
    'featured artist',
    'remixer',
    'songwriter',
    'composer',
    'producer',
    'mixer',
    'recording engineer',
    'mastering engineer',
    'vocal producer'
);


--
-- Name: import_status_enum; Type: TYPE; Schema: schema_; Owner: -
--

CREATE TYPE schema_.import_status_enum AS ENUM (
    'completed',
    'processing',
    'pending',
    'failed'
);


--
-- Name: release_format_enum; Type: TYPE; Schema: schema_; Owner: -
--

CREATE TYPE schema_.release_format_enum AS ENUM (
    'LP',
    'EP',
    'Mixtape',
    'Compilation',
    'Single',
    'album',
    'single',
    'compilation'
);


--
-- Name: artist_followed(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.artist_followed(p_artist_id integer, p_user_id integer) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM schema_.artist_follows
    WHERE followed_artist_id = p_artist_id
      AND user_id            = p_user_id
      AND date_until IS NULL
  );
$$;


--
-- Name: can_like_playlist(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.can_like_playlist(p_playlist_id integer, p_user_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_import_request_streams_added(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_import_request_streams_added() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if old.streams_successfully_added > new.streams_successfully_added then
		raise exception 'Streams cannot decrease!';
	end if;
	return new;
end;
$$;


--
-- Name: check_release_has_artist(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_release_has_artist() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_release_has_song(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_release_has_song() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_release_has_song_after_delete(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_release_has_song_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_song_has_artist(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_song_has_artist() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_song_has_artist_after_delete(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_song_has_artist_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_song_has_release(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_song_has_release() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_user_has_streaming_account(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_user_has_streaming_account() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_user_has_streaming_account_after_delete(); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.check_user_has_streaming_account_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: get_artist_follower_count(integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_artist_follower_count(p_artist_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::integer
  FROM schema_.artist_follows
  WHERE followed_artist_id = p_artist_id AND date_until IS NULL;
$$;


--
-- Name: get_artist_stream_count(integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_artist_stream_count(p_artist_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::integer
  FROM schema_.streams st
  JOIN schema_.songs_artists sa ON sa.song_id = st.song_id
  WHERE sa.artist_id = p_artist_id;
$$;


--
-- Name: get_friends_activity_feed(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_friends_activity_feed(p_user_id integer, p_limit integer DEFAULT 30) RETURNS TABLE(friend_id integer, friend_name text, activity_type text, item_title text, activity_date timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH followed_users AS (
        SELECT followed_user_id 
        FROM schema_.user_follows 
        WHERE user_id = p_user_id AND date_until IS NULL 
    )
    
    SELECT 
        u.id AS friend_id, 
        u.name AS friend_name, 
        'Liked Song'::text AS activity_type, 
        s.title::text AS item_title, 
        sl.date_added AS activity_date
    FROM schema_.song_likes sl
    JOIN schema_.users u ON sl.user_id = u.id
    JOIN schema_.songs s ON sl.song_id = s.id
    WHERE sl.user_id IN (SELECT followed_user_id FROM followed_users)
      AND sl.date_removed IS NULL
      
    UNION ALL

    SELECT 
        u.id AS friend_id, 
        u.name AS friend_name, 
        'Reviewed Release'::text AS activity_type, 
        rel.title::text AS item_title, 
        r.date_added AS activity_date
    FROM schema_.reviews r
    JOIN schema_.users u ON r.user_id = u.id
    JOIN schema_.release_reviews rr ON r.id = rr.review_id
    JOIN schema_.releases rel ON rr.release_id = rel.id
    WHERE r.user_id IN (SELECT followed_user_id FROM followed_users)
      AND r.date_removed IS NULL
      
    ORDER BY activity_date DESC 
    LIMIT p_limit;
END;
$$;


--
-- Name: get_recommended_songs(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_recommended_songs(p_user_id integer, p_limit integer DEFAULT 10) RETURNS TABLE(song_id integer, song_title character varying, recommendation_score bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH target_user_likes AS (
        SELECT sl.song_id
        FROM schema_.song_likes sl
        WHERE sl.user_id = p_user_id
    ),
    similar_users AS (
        SELECT sl.user_id AS similar_user_id, COUNT(sl.song_id) AS similarity_score
        FROM schema_.song_likes sl
        JOIN target_user_likes tul ON sl.song_id = tul.song_id
        WHERE sl.user_id != p_user_id
        GROUP BY sl.user_id
    ),
    candidate_songs AS (
        SELECT sl.song_id, SUM(su.similarity_score) AS total_score
        FROM schema_.song_likes sl
        JOIN similar_users su ON sl.user_id = su.similar_user_id
        WHERE sl.song_id NOT IN (SELECT tul.song_id FROM target_user_likes tul)
        GROUP BY sl.song_id
    )
    
    SELECT 
        s.id AS song_id, 
        s.title AS song_title, 
        cs.total_score::bigint AS recommendation_score
    FROM candidate_songs cs
    JOIN schema_.songs s ON cs.song_id = s.id
    ORDER BY cs.total_score DESC
    LIMIT p_limit;
END;
$$;


--
-- Name: get_release_like_count(integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_release_like_count(p_release_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::integer
  FROM schema_.release_likes
  WHERE release_id = p_release_id AND date_removed IS NULL;
$$;


--
-- Name: get_release_rating(integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_release_rating(p_release_id integer) RETURNS TABLE(average_score numeric, total_reviews bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROUND(AVG(r.score)::numeric, 2) AS average_score,
        COUNT(r.id)::bigint AS total_reviews
    FROM schema_.release_reviews rr
    JOIN schema_.reviews r ON rr.review_id = r.id
    WHERE rr.release_id = p_release_id
      AND r.date_removed IS NULL;
END;
$$;


--
-- Name: get_release_stream_count(integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_release_stream_count(p_release_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::integer
  FROM schema_.streams st
  JOIN schema_.songs_releases sr ON sr.song_id = st.song_id
  WHERE sr.release_id = p_release_id AND sr.removed_date IS NULL;
$$;


--
-- Name: get_song_like_count(integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_song_like_count(p_song_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::integer
  FROM schema_.song_likes
  WHERE song_id = p_song_id AND date_removed IS NULL;
$$;


--
-- Name: get_song_rating(integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_song_rating(p_song_id integer) RETURNS TABLE(average_score numeric, total_reviews bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROUND(AVG(r.score)::numeric, 2) AS average_score,
        COUNT(r.id)::bigint AS total_reviews
    FROM schema_.song_reviews sr
    JOIN schema_.reviews r ON sr.review_id = r.id
    WHERE sr.song_id = p_song_id
      AND r.date_removed IS NULL;
END;
$$;


--
-- Name: get_song_stream_count(integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_song_stream_count(p_song_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::integer
  FROM schema_.streams
  WHERE song_id = p_song_id;
$$;


--
-- Name: get_user_compatibility(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_user_compatibility(p_user_a integer, p_user_b integer) RETURNS TABLE(compatibility_score numeric, common_liked_songs integer, total_liked_songs integer, common_reviewed_songs integer, avg_score_difference numeric)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_intersection   integer;
    v_union          integer;
    v_jaccard        numeric;
    v_common_reviews integer;
    v_avg_diff       numeric;
    v_alignment      numeric;
    v_score          numeric;
BEGIN
    -- Licznenie like'ow
    SELECT COUNT(*)::integer INTO v_intersection
    FROM schema_.song_likes sl_a
    JOIN schema_.song_likes sl_b ON sl_b.song_id = sl_a.song_id
    WHERE sl_a.user_id = p_user_a AND sl_a.date_removed IS NULL
      AND sl_b.user_id = p_user_b AND sl_b.date_removed IS NULL;

    SELECT COUNT(DISTINCT song_id)::integer INTO v_union
    FROM schema_.song_likes
    WHERE user_id IN (p_user_a, p_user_b) AND date_removed IS NULL;

    v_jaccard := CASE WHEN v_union > 0
                      THEN v_intersection::numeric / v_union
                      ELSE 0
                 END;


    -- liczenie sredniej roznicy miedzy ocenami wystawionymi (piosenkom)
    SELECT
        COUNT(*)::integer,
        AVG(ABS(r_a.score - r_b.score))
    INTO v_common_reviews, v_avg_diff
    FROM schema_.song_reviews  sr_a
    JOIN schema_.reviews       r_a ON r_a.id = sr_a.review_id
    JOIN schema_.song_reviews  sr_b ON sr_b.song_id = sr_a.song_id
    JOIN schema_.reviews       r_b ON r_b.id = sr_b.review_id
    WHERE r_a.user_id = p_user_a AND r_a.date_removed IS NULL
      AND r_b.user_id = p_user_b AND r_b.date_removed IS NULL;

    v_alignment := CASE WHEN v_common_reviews > 0
                        THEN 1.0 - (v_avg_diff / 100.0)
                        ELSE NULL
                   END;

    -- liczenie wyniku koncowego
    v_score := ROUND(
        CASE WHEN v_alignment IS NOT NULL
             THEN (v_jaccard * 0.6 + v_alignment * 0.4) * 100
             ELSE  v_jaccard * 100
        END,
    1);

    RETURN QUERY SELECT
        v_score,
        v_intersection,
        v_union,
        v_common_reviews,
        ROUND(v_avg_diff, 1)::numeric;
END;
$$;


--
-- Name: get_user_top_songs(integer, timestamp without time zone, timestamp without time zone, integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.get_user_top_songs(p_user_id integer, p_date_from timestamp without time zone, p_date_to timestamp without time zone, p_days_back integer DEFAULT 30, p_limit integer DEFAULT 10) RETURNS TABLE(song_id integer, song_title character varying, play_count bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id AS song_id, 
        s.title AS song_title, 
        COUNT(str.id)::bigint AS play_count
    FROM schema_.streams str
    JOIN schema_.songs s ON str.song_id = s.id
    WHERE str.user_id = p_user_id 
      AND str.stream_timestamp BETWEEN p_date_from AND p_date_to
    GROUP BY s.id, s.title
    ORDER BY play_count DESC
    LIMIT p_limit;
END;
$$;


--
-- Name: release_liked(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.release_liked(p_release_id integer, p_user_id integer) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM schema_.release_likes
    WHERE release_id = p_release_id
      AND user_id    = p_user_id
      AND date_removed IS NULL
  );
$$;


--
-- Name: release_my_score(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.release_my_score(p_release_id integer, p_user_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT rv.score
  FROM schema_.release_reviews rr
  JOIN schema_.reviews rv ON rv.id = rr.review_id
  WHERE rr.release_id    = p_release_id
    AND rv.user_id       = p_user_id
    AND rv.date_removed IS NULL
  LIMIT 1;
$$;


--
-- Name: song_liked(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.song_liked(p_song_id integer, p_user_id integer) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM schema_.song_likes
    WHERE song_id = p_song_id
      AND user_id = p_user_id
      AND date_removed IS NULL
  );
$$;


--
-- Name: song_my_score(integer, integer); Type: FUNCTION; Schema: schema_; Owner: -
--

CREATE FUNCTION schema_.song_my_score(p_song_id integer, p_user_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT r.score
  FROM schema_.song_reviews sr
  JOIN schema_.reviews r ON r.id = sr.review_id
  WHERE sr.song_id      = p_song_id
    AND r.user_id       = p_user_id
    AND r.date_removed IS NULL
  LIMIT 1;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;


--
-- Name: artist_follows; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.artist_follows (
    user_id integer NOT NULL,
    followed_artist_id integer NOT NULL,
    date_from timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_until timestamp without time zone,
    CONSTRAINT cns_artist_follows CHECK (((date_until IS NULL) OR (date_from < date_until)))
);


--
-- Name: artist_roles_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

CREATE SEQUENCE schema_.artist_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: artist_roles; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.artist_roles (
    id integer DEFAULT nextval('schema_.artist_roles_id_seq'::regclass) NOT NULL,
    name text
);


--
-- Name: artists_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

CREATE SEQUENCE schema_.artists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: artists; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.artists (
    id integer DEFAULT nextval('schema_.artists_id_seq'::regclass) NOT NULL,
    stage_name text NOT NULL,
    birth_date date,
    website text,
    profile_picture text,
    description text,
    spotify_id text,
    spotify_enriched boolean DEFAULT false NOT NULL
);


--
-- Name: artists_aliases; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.artists_aliases (
    artist_id integer NOT NULL,
    artist_alias text NOT NULL,
    CONSTRAINT chk_alias_not_empty CHECK ((TRIM(BOTH FROM artist_alias) <> ''::text))
);


--
-- Name: artists_releases; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.artists_releases (
    artist_id integer NOT NULL,
    release_id integer NOT NULL,
    artist_role_id integer NOT NULL
);


--
-- Name: songs_artists; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.songs_artists (
    song_id integer NOT NULL,
    artist_id integer NOT NULL,
    artist_role schema_.artist_role_enum NOT NULL
);


--
-- Name: streams_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

CREATE SEQUENCE schema_.streams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: streams; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.streams (
    id integer DEFAULT nextval('schema_.streams_id_seq'::regclass) NOT NULL,
    song_id integer NOT NULL,
    user_id integer NOT NULL,
    stream_timestamp timestamp without time zone NOT NULL
);


--
-- Name: artists_detail; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.artists_detail AS
 SELECT id,
    stage_name,
    spotify_id,
    ( SELECT (count(DISTINCT sa.song_id))::integer AS count
           FROM schema_.songs_artists sa
          WHERE (sa.artist_id = a.id)) AS song_count,
    ( SELECT (count(DISTINCT ar.release_id))::integer AS count
           FROM schema_.artists_releases ar
          WHERE (ar.artist_id = a.id)) AS release_count,
    ( SELECT (count(*))::integer AS count
           FROM schema_.artist_follows
          WHERE ((artist_follows.followed_artist_id = a.id) AND (artist_follows.date_until IS NULL))) AS follower_count,
    ( SELECT (count(*))::integer AS count
           FROM (schema_.streams st
             JOIN schema_.songs_artists sa ON ((sa.song_id = st.song_id)))
          WHERE (sa.artist_id = a.id)) AS stream_count
   FROM schema_.artists a;


--
-- Name: genres_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

CREATE SEQUENCE schema_.genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genres; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.genres (
    id integer DEFAULT nextval('schema_.genres_id_seq'::regclass) NOT NULL,
    name text NOT NULL,
    subgenre_of integer
);


--
-- Name: import_errors; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.import_errors (
    id integer NOT NULL,
    import_id integer NOT NULL,
    error_message text NOT NULL,
    raw_json_record jsonb NOT NULL
);


--
-- Name: import_requests; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.import_requests (
    id integer NOT NULL,
    status schema_.import_status_enum NOT NULL,
    user_id integer NOT NULL,
    file_name text NOT NULL,
    file_hash text NOT NULL,
    total_streams_found integer DEFAULT 0 NOT NULL,
    streams_successfully_added integer DEFAULT 0 NOT NULL,
    upload_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_date timestamp without time zone,
    CONSTRAINT cns_import_requests CHECK (((completed_date IS NULL) OR (completed_date <= upload_date))),
    CONSTRAINT cns_import_requests_0 CHECK ((streams_successfully_added <= total_streams_found))
);



--
-- Name: playlist_likes; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.playlist_likes (
    playlist_id integer NOT NULL,
    user_id integer NOT NULL,
    date_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_removed timestamp without time zone,
    CONSTRAINT cns_playlist_likes CHECK (((date_removed IS NULL) OR (date_added < date_removed))),
    CONSTRAINT playlist_likes_possible CHECK (schema_.can_like_playlist(playlist_id, user_id))
);


--
-- Name: playlist_owners; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.playlist_owners (
    playlist_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: playlist_songs; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.playlist_songs (
    playlist_id integer NOT NULL,
    song_id integer NOT NULL,
    date_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_removed timestamp without time zone,
    user_id integer NOT NULL,
    CONSTRAINT cns_playlist_songs CHECK (((date_removed IS NULL) OR (date_added < date_removed)))
);


--
-- Name: songs_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

CREATE SEQUENCE schema_.songs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: songs; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.songs (
    id integer DEFAULT nextval('schema_.songs_id_seq'::regclass) NOT NULL,
    title character varying(100) NOT NULL,
    duration_ms integer NOT NULL,
    spotify_id text,
    CONSTRAINT cns_songs CHECK ((duration_ms > 0))
);


--
-- Name: users; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.users (
    id integer NOT NULL,
    name text NOT NULL,
    passwd text NOT NULL,
    date_joined timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_left timestamp without time zone,
    CONSTRAINT cns_users CHECK (((date_left IS NULL) OR (date_joined < date_left)))
);


--
-- Name: playlist_songs_detail; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.playlist_songs_detail AS
 SELECT ps.playlist_id,
    s.id AS song_id,
    s.title,
    s.duration_ms,
    s.spotify_id,
    ps.date_added,
    u.name AS added_by,
    ( SELECT array_agg(DISTINCT a.stage_name) AS array_agg
           FROM (schema_.songs_artists sa
             JOIN schema_.artists a ON ((a.id = sa.artist_id)))
          WHERE (sa.song_id = s.id)) AS artists
   FROM ((schema_.playlist_songs ps
     JOIN schema_.songs s ON ((s.id = ps.song_id)))
     JOIN schema_.users u ON ((u.id = ps.user_id)))
  WHERE (ps.date_removed IS NULL);


--
-- Name: playlists_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

CREATE SEQUENCE schema_.playlists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: playlists; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.playlists (
    id integer DEFAULT nextval('schema_.playlists_id_seq'::regclass) NOT NULL,
    date_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_removed timestamp without time zone,
    cover text DEFAULT 'untitled.png'::text NOT NULL,
    is_private boolean DEFAULT false NOT NULL,
    name text,
    CONSTRAINT cns_playlists CHECK (((date_removed IS NULL) OR (date_added < date_removed)))
);


--
-- Name: playlists_detail; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.playlists_detail AS
 SELECT id,
    name,
    is_private,
    cover,
    date_added,
    ( SELECT array_agg(DISTINCT u.name) AS array_agg
           FROM (schema_.playlist_owners po
             JOIN schema_.users u ON ((u.id = po.user_id)))
          WHERE (po.playlist_id = p.id)) AS owners,
    ( SELECT (count(DISTINCT ps.song_id))::integer AS count
           FROM schema_.playlist_songs ps
          WHERE ((ps.playlist_id = p.id) AND (ps.date_removed IS NULL))) AS song_count
   FROM schema_.playlists p
  WHERE (date_removed IS NULL);


--
-- Name: release_covers; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.release_covers (
    id integer NOT NULL,
    cover text NOT NULL,
    release_id integer NOT NULL,
    used_since timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    used_until timestamp without time zone,
    CONSTRAINT cns_release_covers CHECK (((used_until IS NULL) OR (used_since < used_until)))
);


--
-- Name: release_likes; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.release_likes (
    release_id integer NOT NULL,
    user_id integer NOT NULL,
    date_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_removed timestamp without time zone,
    CONSTRAINT cns_release_likes CHECK (((date_removed IS NULL) OR (date_added < date_removed)))
);


--
-- Name: release_reviews; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.release_reviews (
    release_id integer NOT NULL,
    review_id integer NOT NULL
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

CREATE SEQUENCE schema_.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.reviews (
    id integer DEFAULT nextval('schema_.reviews_id_seq'::regclass) NOT NULL,
    score integer NOT NULL,
    user_id integer NOT NULL,
    date_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_removed timestamp without time zone,
    body text,
    CONSTRAINT cns_reviews CHECK (((date_removed IS NULL) OR (date_added < date_removed))),
    CONSTRAINT reviews_score_range CHECK (((score >= 0) AND (score <= 100)))
);


--
-- Name: release_reviews_detail; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.release_reviews_detail AS
 SELECT rr.release_id,
    r.id AS review_id,
    r.score,
    r.date_added,
    u.id AS user_id,
    u.name AS username
   FROM ((schema_.release_reviews rr
     JOIN schema_.reviews r ON ((r.id = rr.review_id)))
     JOIN schema_.users u ON ((u.id = r.user_id)))
  WHERE (r.date_removed IS NULL);


--
-- Name: release_scores; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.release_scores AS
 SELECT rr.release_id,
    round(avg(r.score), 2) AS avg_score,
    (count(*))::integer AS review_count
   FROM (schema_.release_reviews rr
     JOIN schema_.reviews r ON ((r.id = rr.review_id)))
  WHERE (r.date_removed IS NULL)
  GROUP BY rr.release_id;


--
-- Name: releases_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

CREATE SEQUENCE schema_.releases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: releases; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.releases (
    id integer DEFAULT nextval('schema_.releases_id_seq'::regclass) NOT NULL,
    title character varying(100) NOT NULL,
    release_date date NOT NULL,
    format schema_.release_format_enum NOT NULL,
    main_cover_id integer,
    spotify_id text,
    spotify_enriched boolean DEFAULT false NOT NULL
);


--
-- Name: songs_releases; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.songs_releases (
    song_id integer NOT NULL,
    release_id integer NOT NULL,
    added_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    removed_date timestamp without time zone,
    CONSTRAINT cns_songs_releases CHECK (((removed_date IS NULL) OR (added_date < removed_date)))
);


--
-- Name: releases_detail; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.releases_detail AS
 SELECT id,
    title,
    format,
    release_date,
    spotify_id,
    main_cover_id,
    ( SELECT array_agg(DISTINCT a.stage_name) AS array_agg
           FROM (schema_.artists_releases ar
             JOIN schema_.artists a ON ((a.id = ar.artist_id)))
          WHERE (ar.release_id = r.id)) AS artists,
    ( SELECT round(avg(rv.score), 2) AS round
           FROM (schema_.release_reviews rr
             JOIN schema_.reviews rv ON ((rv.id = rr.review_id)))
          WHERE ((rr.release_id = r.id) AND (rv.date_removed IS NULL))) AS avg_score,
    ( SELECT (count(*))::integer AS count
           FROM schema_.release_likes
          WHERE ((release_likes.release_id = r.id) AND (release_likes.date_removed IS NULL))) AS like_count,
    ( SELECT (count(*))::integer AS count
           FROM (schema_.streams st
             JOIN schema_.songs_releases sr ON ((sr.song_id = st.song_id)))
          WHERE ((sr.release_id = r.id) AND (sr.removed_date IS NULL))) AS stream_count
   FROM schema_.releases r;


--
-- Name: releases_genres; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.releases_genres (
    genre_id integer NOT NULL,
    release_id integer NOT NULL
);



--
-- Name: song_likes; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.song_likes (
    user_id integer NOT NULL,
    song_id integer NOT NULL,
    date_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_removed timestamp without time zone,
    CONSTRAINT cns_song_likes CHECK (((date_removed IS NULL) OR (date_added < date_removed)))
);


--
-- Name: song_reviews; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.song_reviews (
    song_id integer NOT NULL,
    review_id integer NOT NULL
);


--
-- Name: song_reviews_detail; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.song_reviews_detail AS
 SELECT sr.song_id,
    r.id AS review_id,
    r.score,
    r.date_added,
    u.id AS user_id,
    u.name AS username
   FROM ((schema_.song_reviews sr
     JOIN schema_.reviews r ON ((r.id = sr.review_id)))
     JOIN schema_.users u ON ((u.id = r.user_id)))
  WHERE (r.date_removed IS NULL);


--
-- Name: song_scores; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.song_scores AS
 SELECT sr.song_id,
    round(avg(r.score), 2) AS avg_score,
    (count(*))::integer AS review_count
   FROM (schema_.song_reviews sr
     JOIN schema_.reviews r ON ((r.id = sr.review_id)))
  WHERE (r.date_removed IS NULL)
  GROUP BY sr.song_id;


--
-- Name: songs_detail; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.songs_detail AS
 SELECT id,
    title,
    duration_ms,
    spotify_id,
    ( SELECT array_agg(DISTINCT a.stage_name) AS array_agg
           FROM (schema_.songs_artists sa
             JOIN schema_.artists a ON ((a.id = sa.artist_id)))
          WHERE (sa.song_id = s.id)) AS artists,
    ( SELECT round(avg(r.score), 2) AS round
           FROM (schema_.song_reviews sr
             JOIN schema_.reviews r ON ((r.id = sr.review_id)))
          WHERE ((sr.song_id = s.id) AND (r.date_removed IS NULL))) AS avg_score,
    ( SELECT (count(*))::integer AS count
           FROM schema_.song_likes
          WHERE ((song_likes.song_id = s.id) AND (song_likes.date_removed IS NULL))) AS like_count,
    ( SELECT (count(*))::integer AS count
           FROM schema_.streams
          WHERE (streams.song_id = s.id)) AS stream_count
   FROM schema_.songs s;


--
-- Name: songs_genres; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.songs_genres (
    song_id integer NOT NULL,
    genre_id integer NOT NULL
);


--
-- Name: streaming_accounts; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.streaming_accounts (
    user_id integer NOT NULL,
    streaming_id text NOT NULL,
    access_token text NOT NULL,
    refresh_token text NOT NULL,
    token_expires_at timestamp without time zone NOT NULL
);


--
-- Name: streams_detail; Type: VIEW; Schema: schema_; Owner: -
--

CREATE VIEW schema_.streams_detail AS
 SELECT st.id,
    st.user_id,
    st.stream_timestamp,
    s.id AS song_id,
    s.title AS song_title,
    s.duration_ms,
    s.spotify_id AS song_spotify_id,
    ( SELECT array_agg(DISTINCT a.stage_name) AS array_agg
           FROM (schema_.songs_artists sa
             JOIN schema_.artists a ON ((a.id = sa.artist_id)))
          WHERE (sa.song_id = s.id)) AS artists,
    rel.title AS release_title,
    rel.format AS release_format
   FROM (((schema_.streams st
     JOIN schema_.songs s ON ((s.id = st.song_id)))
     LEFT JOIN schema_.songs_releases sr ON (((sr.song_id = s.id) AND (sr.removed_date IS NULL))))
     LEFT JOIN schema_.releases rel ON ((rel.id = sr.release_id)));


--
-- Name: user_follows; Type: TABLE; Schema: schema_; Owner: -
--

CREATE TABLE schema_.user_follows (
    user_id integer NOT NULL,
    followed_user_id integer NOT NULL,
    date_from timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_until timestamp without time zone,
    CONSTRAINT chk_no_self_follow CHECK ((user_id <> followed_user_id)),
    CONSTRAINT cns_user_follows CHECK (((date_until IS NULL) OR (date_from < date_until)))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: schema_; Owner: -
--

ALTER TABLE schema_.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME schema_.users_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: artist_follows; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.artist_follows (user_id, followed_artist_id, date_from, date_until) FROM stdin;
1	1	2026-05-29 17:54:33.793354	\N
114	292	2026-05-31 14:29:24.519546	\N
114	133	2026-05-31 14:29:23.819976	2026-05-31 20:52:23.361425
114	133	2026-05-31 20:52:29.599698	\N
\.


--
-- Data for Name: artist_roles; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.artist_roles (id, name) FROM stdin;
1	main artist
\.


--
-- Data for Name: artists; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.artists (id, stage_name, birth_date, website, profile_picture, description, spotify_id, spotify_enriched) FROM stdin;
1	The Beatles	1960-01-01	https://thebeatles.com	\N	Legendarny zespół rockowy z Liverpoolu.	\N	f
2	Daft Punk	1993-01-01	https://daftpunk.com	\N	Francuski duet muzyki elektronicznej.	\N	f
2010	Dominic Fike	\N	\N	\N	\N	6USv9qhCn6zfxlBQIYJ9qs	f
1981	roro	\N	\N	\N	\N	0Y9jBmQGmBdDhlu3bSxECs	f
2304	A$AP NAST	\N	\N	\N	\N	1uLYUm2A6kpFYAECfAFoH1	f
2305	A$AP Twelvyy	\N	\N	\N	\N	0tPjSrb43a58uznKru1k2P	f
1983	SoGone SoFlexy	\N	\N	\N	\N	59TV2OX3lSIlALY4zlFPh4	f
2307	Chace Infinite	\N	\N	\N	\N	4jzvaIdQqLBp0wW2ZYkFAu	f
2308	SpaceGhostPurrp	\N	\N	\N	\N	6yR6M6V6I7GhhYf6A7Wif9	f
1994	Makana XO	\N	\N	\N	\N	72Skr9uHuQfIT7ezeKuvt1	f
1998	Diego	\N	\N	\N	\N	0OYWzJ18WncEBUWBrmpX0O	f
138	feeble little horse	\N	\N	\N	\N	2GJa7lPCjAB1rKXptXrfy8	f
2312	Main Attrakionz	\N	\N	\N	\N	3jdktm1PgLu9u3tS1YUKrW	f
18	Olēka	\N	\N	\N	\N	0lpq5rqUEmlUaVWHS84BpY	f
394	Lowercase Committee	\N	\N	\N	\N	4zVgqiUlyIzofO4pqiKW9y	f
292	COLORS	\N	\N	\N	\N	3FvwVFWRyvxmLyVBO9nBmM	f
391	Buzzy Lee	\N	\N	\N	\N	0cz2DZrX5wGn1XUdIPKYYQ	f
2135	billy woods	\N	\N	\N	\N	39vtb2iiz3079nqfL5nfFc	f
140	venturing	\N	\N	\N	\N	13xKCVJaX32BL7EN9IOiCM	f
2008	Sekou	\N	\N	\N	\N	1mYgKcXdbklH5RwjU6XA8c	f
20	underscores	\N	\N	\N	\N	7HfUJxeVTgrvhk0eWHFzV7	f
10	JPEGMAFIA	\N	\N	\N	\N	6yJ6QQ3Y5l0s0tn7b0arrO	f
2013	DERBY	\N	\N	\N	\N	5WFUn8WTVNDiOHZCEzxIQZ	f
50	Jane Remover	\N	\N	\N	\N	2rLGlNI6htigNxx172qxLu	f
66	Kevin Abstract	\N	\N	\N	\N	07EcmJpfAday8xGkslfanE	f
2144	gabby start	\N	\N	\N	\N	33L1klom7IXmoAP8fjrGm9	f
133	brakence	\N	\N	\N	\N	4kqFrZkeqDfOIEqTWqbOOV	f
1987	E Bleu	\N	\N	\N	\N	5iFK29ta4wFeMTSqxc4CMt	f
2021	Devan	\N	\N	\N	\N	1F4bxn7kvD9Ba0px6adsT5	f
713	Ameer Vann	\N	\N	\N	\N	7kIbB1pdDyehFj8aNgfzfH	f
2011	Geezer	\N	\N	\N	\N	1Px3z0pAOyBLWpcFPb5VYH	f
38	kmoe	\N	\N	\N	\N	48wt14F9gzlkNDRdXyJTQz	f
2185	A$AP Rocky	\N	\N	\N	\N	13ubrt8QOOCPljQ2FL1Kca	f
1999	Drigo	\N	\N	\N	\N	22SOlSw4QOrYYarJbS2VA6	f
2152	henhouse!	\N	\N	\N	\N	2P6QtistbdtrLkmklK0Aw6	f
1996	Truly Young	\N	\N	\N	\N	6Hqu0lCYGK2QO1vp4rwDMS	f
1572	Belmondo	\N	\N	\N	\N	3LDKqGmw6GyxO81YdtMAgl	f
1985	Love Spells	\N	\N	\N	\N	5iiqhuffUTPEOjAUDj19IW	f
1991	Danny Brown	\N	\N	\N	\N	7aA592KWirLsnfb5ulGWvU	f
2646	Sunday Service Choir	\N	\N	\N	\N	2c9O21YLFy4tFI9zCVhbFg	f
4	Quadeca	\N	\N	\N	\N	3zz52ViyCBcplK0ftEVPSS	f
2648	Thor Harris	\N	\N	\N	\N	4Td98UbNadNYhS8LnMsgBQ	f
599	Kenny Mason	\N	\N	\N	\N	4mwdnO2jZrMmMVrjcHsZBv	f
601	Paris Texas	\N	\N	\N	\N	1SCrMreNPJYSRZIlRe9SUq	f
2111	SMJ	\N	\N	\N	\N	4pDtAjA47T0lTKu97HfNfq	f
589	forgive yourself	\N	\N	\N	\N	4R0PDznz6UhsZTqglLC8Yq	f
2056	Maruja	\N	\N	\N	\N	71ISXR7gtIq5E2AdI3jGf0	f
520	By Storm	\N	\N	\N	\N	1YUIjQ3ugjokiyb908LpVO	f
2114	JID	\N	\N	\N	\N	6U3ybJ9UHNKEdsH7ktGBZ7	f
521	Injury Reserve	\N	\N	\N	\N	3nf2EaHj8HikLNdaiW3v73	f
2299	ScHoolboy Q	\N	\N	\N	\N	5IcR3N7QB1j6KBL8eImZ8m	f
2302	Fat Tony	\N	\N	\N	\N	3N71zVVdCs6uCgk8w31v26	f
\.


--
-- Data for Name: artists_aliases; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.artists_aliases (artist_id, artist_alias) FROM stdin;
1	The Fab Four
2	Guy-Manuel & Thomas
\.


--
-- Data for Name: artists_releases; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.artists_releases (artist_id, release_id, artist_role_id) FROM stdin;
4	4	1
10	7	1
18	11	1
20	12	1
4	15	1
38	21	1
50	27	1
66	35	1
4	44	1
50	67	1
138	69	1
140	70	1
50	100	1
4	142	1
292	142	1
394	189	1
520	247	1
521	247	1
589	278	1
599	283	1
520	325	1
521	325	1
20	336	1
4	337	1
50	339	1
1572	720	1
2185	870	1
4	1021	1
\.


--
-- Data for Name: genres; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.genres (id, name, subgenre_of) FROM stdin;
1	Rock	\N
2	Electronic	\N
3	Pop Rock	1
\.


--
-- Data for Name: import_errors; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.import_errors (id, import_id, error_message, raw_json_record) FROM stdin;
1	1	Brak metadanych utworu	{"artist": "Unknown", "msPlayed": 0}
\.


--
-- Data for Name: import_requests; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.import_requests (id, status, user_id, file_name, file_hash, total_streams_found, streams_successfully_added, upload_date, completed_date) FROM stdin;
1	completed	1	history_export.json	sha256_hash_123	0	0	2026-05-29 17:54:33.797788	\N
\.


--
-- Data for Name: playlist_likes; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.playlist_likes (playlist_id, user_id, date_added, date_removed) FROM stdin;
\.


--
-- Data for Name: playlist_owners; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.playlist_owners (playlist_id, user_id) FROM stdin;
1	1
2	2
3	114
\.


--
-- Data for Name: playlist_songs; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.playlist_songs (playlist_id, song_id, date_added, date_removed, user_id) FROM stdin;
1	1	2026-05-29 17:54:33.796356	\N	1
3	101	2026-05-31 14:28:47.183847	\N	114
3	142	2026-05-31 14:28:50.034391	\N	114
3	67	2026-05-31 14:28:51.935188	\N	114
3	69	2026-05-31 14:28:54.071349	\N	114
\.


--
-- Data for Name: playlists; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.playlists (id, date_added, date_removed, cover, is_private, name) FROM stdin;
1	2026-05-29 17:54:33.78934	\N	untitled.png	t	Moje Ulubione
2	2026-05-29 17:54:33.78934	\N	untitled.png	f	Do Biegania
3	2026-05-31 14:28:29.921179	\N	untitled.png	t	testtesttest
\.


--
-- Data for Name: release_covers; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.release_covers (id, cover, release_id, used_since, used_until) FROM stdin;
101	let_it_be_cover.jpg	1	2026-05-29 17:54:33.789768	\N
102	daft_punk_ram.png	2	2026-05-29 17:54:33.789768	\N
\.


--
-- Data for Name: release_likes; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.release_likes (release_id, user_id, date_added, date_removed) FROM stdin;
1	1	2026-05-29 17:54:33.794852	\N
4	114	2026-05-31 20:52:32.350784	\N
69	114	2026-05-31 20:52:33.417225	\N
189	114	2026-05-31 20:52:33.849668	\N
7	114	2026-05-31 20:52:34.246714	\N
\.


--
-- Data for Name: release_reviews; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.release_reviews (release_id, review_id) FROM stdin;
2	2
\.


--
-- Data for Name: releases; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.releases (id, title, release_date, format, main_cover_id, spotify_id, spotify_enriched) FROM stdin;
1	Let It Be (Album)	1970-05-08	LP	101	\N	f
2	Random Access Memories	2013-05-17	LP	102	\N	f
11	Sunshine When It Rains / See The World	2025-10-15	single	\N	7CkY3b34iF8CMlvIOLusfH	f
100	♡	2025-12-05	single	\N	2XeflvA0dNvjpX0vxukgiv	f
142	MONDAY - A COLORS SHOW	2025-12-04	single	\N	2tcooZLhliuKYR5da5BAgT	f
189	Good Luck Charm	2026-05-26	single	\N	76EQbB0jHsT8sE4fLjzzCr	f
4	Dark Magic	2026-05-27	single	\N	1iBUPWKDIoHqRhNxmnNQps	t
7	EXPERIMENTAL RAP	2026-05-21	album	\N	5LmWpQ3tnLtX0kOm2SxB22	t
12	U	2026-03-20	album	\N	1qSS0T6Ffrb3rFVpizzOuk	t
15	SCRAPYARD	2024-02-16	album	\N	2uoD60Oip7rq3vjXxZ2VaD	t
21	K1	2025-06-06	album	\N	6f7CThvZW0bwczICdR0yHV	t
27	Frailty	2021-11-12	album	\N	6rO7DlLYSHabzSsD7Gpe14	t
35	Blush	2025-06-27	album	\N	59pGTYofVrG2K6Q12h7gm0	t
44	Vanisher, Horizon Scraper	2025-07-25	album	\N	6o6VAIetIFOsaOa0qt7w9u	t
67	Revengeseekerz	2025-04-04	album	\N	21b4cDNse2AMpj94ykfuON	t
69	bitknot	2026-05-26	album	\N	5wpfyoOxAVSVtzszRHVcIZ	t
70	Ghostholding	2025-02-14	album	\N	0zfRCNRF2ya1KZDtgGXUgI	t
247	Double Trio	2023-08-02	single	\N	1qR1PsR864ftJ56nXGZNYz	t
278	Songs I'll Never Release	2024-11-21	single	\N	6a1cLgO7MZ6nFJcRfh5kjE	t
283	BULLDAWG	2026-05-12	album	\N	4b0qE7wgMfoDD5HU9NOPiH	t
325	My Ghosts Go Ghost	2026-01-30	album	\N	3PVx0nf16eZmTOiTu33UaK	t
336	Wallsocket	2023-09-22	album	\N	0mQPq9INcTC48siErksOrl	t
337	Vanisher, Horizon Scraper (The Extended Cut)	2026-02-03	album	\N	3ZfqSEOlHerP9UZJfu4tSD	t
339	Teen Week	2021-02-26	single	\N	2zaNeL1xFEOp7on5ZJXJSA	t
720	Mordo jak tam zdrowie	2017-01-01	single	\N	0Fy8hZYb2rYXyGy0mO7Cne	t
870	LIVE.LOVE.A$AP	2011-10-31	album	\N	4l6EPpP9hjQrLb8qNB9eC5	t
1021	I Didn't Mean To Haunt You	2022-11-10	album	\N	3c0NHNo2Gn0X7uARad3hGv	t
\.


--
-- Data for Name: releases_genres; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.releases_genres (genre_id, release_id) FROM stdin;
3	1
2	2
\.



--
-- Data for Name: reviews; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.reviews (id, score, user_id, date_added, date_removed, body) FROM stdin;
1	10	1	2026-05-29 17:54:33.795122	\N	\N
2	9	2	2026-05-29 17:54:33.795122	\N	\N
3	100	114	2026-05-31 20:43:35.905664	\N	\N
4	20	114	2026-05-31 20:53:02.387842	\N	\N
5	100	114	2026-05-31 20:53:11.270002	\N	\N
6	100	114	2026-05-31 21:31:18.112685	\N	\N
7	67	114	2026-05-31 21:31:21.678222	\N	\N
8	90	114	2026-05-31 21:31:25.192232	\N	\N
9	100	114	2026-05-31 21:31:29.440986	\N	\N
10	100	114	2026-05-31 21:31:34.099637	\N	\N
\.


--
-- Data for Name: song_likes; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.song_likes (user_id, song_id, date_added, date_removed) FROM stdin;
1	1	2026-05-29 17:54:33.794319	\N
2	2	2026-05-29 17:54:33.794319	\N
114	142	2026-05-31 14:29:04.200325	\N
114	101	2026-05-31 14:29:05.054009	\N
114	100	2026-05-31 14:29:05.902387	\N
114	1080	2026-05-31 21:31:10.608894	\N
114	1079	2026-05-31 21:31:11.064665	\N
114	1077	2026-05-31 21:31:11.457311	\N
114	1076	2026-05-31 21:31:11.874337	\N
114	1075	2026-05-31 21:31:12.274336	\N
114	1071	2026-05-31 21:31:13.358544	\N
114	1070	2026-05-31 21:31:35.025548	\N
114	1073	2026-05-31 21:31:12.810663	2026-05-31 21:36:13.239317
114	1073	2026-05-31 21:36:13.715558	\N
\.


--
-- Data for Name: song_reviews; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.song_reviews (song_id, review_id) FROM stdin;
1	1
280	3
333	4
332	5
1077	6
1076	7
1075	8
1071	9
1070	10
\.


--
-- Data for Name: songs; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.songs (id, title, duration_ms, spotify_id) FROM stdin;
1	Let It Be	243000	\N
2	Get Lucky	368000	\N
4	Dark Magic	175047	60hga4vu4erXRxcxEGDLMQ
7	Mask On	153888	1b5DLiOTtF2MORXJz6dyJQ
11	Sunshine When It Rains	316962	2dCIGxwbZPZwrWHGvSy71O
12	Lovefield	232394	6rIsZ4WR4aENaUXOcLEfR0
15	DUSTCUTTER	164179	0fC23QgwF2sIM7hRTJhfov
20	TSAR BOMBA	106573	11zqgiZxvNCb1pCgJxw99V
21	Watershed	169732	7vZVX0guC9RMgY5LaxWUGY
27	search party	298181	490NAHwXWtwve0t4J2Q0D0
35	Abandon Me	160567	2al0D4c36NkkQY9NQbYjxE
44	GODSTAINED	205244	6phik4BkqTBtDodw8ZJJ5Q
64	Music	207296	6gPbjxlebqkFyCaLY4SRVm
65	Dumpster fire	165160	6joVOYeKHWl5g744BuB3dg
66	A LA CARTE	181942	2yVMxWhM3LHmo3UVR0VVrZ
67	Dark night castle	258920	3d3v3dstj9yP3XmjY22Fdl
68	Burning Hammer	193691	5C7TRctHokAGPz1JHAxgx7
69	Poison	100786	3ZCceTIHGCu9iYW9BJCtHZ
70	Recoil	202046	5mqLILLUShe2rjaV1dcqPr
81	GYBB	119764	4lzukCL4tiespb73ejGYnf
82	See The World	338299	12jrSjP82YIlsX01ZsATmB
100	Music Baby	320566	3heQu7YLQFf0WY4Z2giXhk
101	FORGONE	474662	50SUl5f6BMCWSV2JX1TAWh
142	MONDAY - A COLORS SHOW	246709	2HUYmOmEMZC59UhCKokzAp
164	Thousand yard stare	198192	0kE9Sx06mOikMnb7e6AtXR
187	Bridges on Fire	173382	6gkXRvq7zdF5tupL7wpXXo
188	U DON’T KNOW ME LIKE THAT	209319	5K8lOqPnsWh9QNSgNBqhO2
189	Good Luck Charm	169870	1mxAl56K6iFEt6cjxPymQD
213	Fadeoutz	200571	5XNf2R7PzOkaBKeaBUREJS
240	GUIDE DOG	121364	496Dg6Snf7Q3LyRLFjjGaf
241	Believe	219143	5cvFePHQn46kDhgruTPV3M
242	Star people	259139	44Obh48yje3RZvWtYc4OpJ
243	Pop this Heat	116089	0U1uQvYa0FTXSadLoBe4tE
244	Shopping	160253	3p89R8FQCXeliR37Jv6zKI
245	WAGING WAR	315182	4AJWlmqzFwDuCWozzjxTjO
246	Do I keep you up	139562	04qjgWsa6urhAauXYWe3Qi
247	Double Trio	416202	2BPfpIAHA1GpqkLR9sQPMD
275	MONDAY	243664	3a9Qmzy2dqZsa8QAggkioN
276	The Ghost Of Emmett Till	116342	0rIQ00YTQMY0EPy01bQWzI
278	Mad at Me	163761	5avJdJjXtHN9ADFeSn1pDq
279	WHAT’S IT TO HIM?	154618	3YMFWJvV0s2ZNpcFBkI0CJ
280	DANCING WITHOUT MOVING	199403	1TGiB4KEDY8dlpXrIWQ2f1
281	goldfish	181042	7A8YnjMhMrTfVqMRRfayv7
282	Lights	182702	797VSqbtTiNuxMFIgcGAuo
283	BE WHAT I WANT (feat. Paris Texas)	221986	76bdOE5Azj2KHN9NnpqdWn
284	idiot	189277	4Dd0onhwJQortMphWLaKzh
320	One Step Program	91585	5SmHQ7l8P2fHRgyzkrTCwK
325	In My Town	422068	1wlYr1YDvk1Y7NBYdIdi6N
327	RUIN MY LIFE	281828	7JzTTmvNedMzaYwijsJhxA
328	The way I should	154812	4Lc0vIR0CHlJu8tTVFDGrd
329	No sleep	200446	0b0bOG64dBylIiemVhsGxu
330	Bodyfeeling	248100	1hXtXrkP0n04Cx5DUyQNdX
331	No Strippers In Heaven	152096	55DNyl5GuEqcy3SrVUJZ6z
332	WAY TOO MANY FRIENDS	128026	61XwdJoiks6cXNNFJDJVcQ
333	Red Light	188451	4MSWocQxEUa19FOZr745LB
334	Carpet	240127	5DTqcZlVd7HmXxRAIcWKZo
335	We don't exist	255617	2528bOwiGNc8UAavrvzLnb
336	Duhhhhhhhhhhhhhhhhh	247796	2YCB6feHqTwywcF5xw8tMN
337	MELISA	216756	7gBXc7NLb6e6tBdb4dJPW7
338	New Era	147135	3Eh6giuzG1YSo5pk2CTaKT
339	homeswitcher	145183	3wGDs4CbpDqpsTYyN5pe8o
340	Don't be like mouse	172544	0aNdtLrUvMMSKZ2EqEFYJK
341	Famous girl	234857	5CTanXNx9NNMPPF3q1EWy4
342	The Peace	169500	6wm3t4VpTxSFfOUgTMlHZM
570	EASIER	205453	7JzaVyLO9WhgAj2VHHedhT
670	Chat	186658	2487pc2YTCH1r2Jf4bxNbJ
720	Mordo jak tam zdrowie	125952	4npoZoCUrlU9uKPN4rqnhD
871	投影の芸術	57320	3zV8BUkLyVvahUQpKKsM2I
872	babygirl	147491	3iyEtTlvlb0fiYGzIvD7S7
874	$ (Money)	135324	0gSJ32sIBQQvGhCatvW4nO
876	Meet the Dealers	161557	2EpHHxjFYlNRYPxL43YesS
877	head	103470	7CmnSuJwVeBLC5dS7bXcA6
878	Degenerates Prayer	133041	51F6IBCglbWYbYaSXnT22O
880	Since I Met Ye	118663	4PmLwDkAMzpwzcvNm3nOjB
881	¥ (Yen)	120570	10D52Ymf8mtTvPPdQ5HIyS
885	His Will	67047	6pp8zxnDmbg6Ih4mRf9TpO
888	One Day it Will Be Over	44188	4uwfcuxaL8KGWcPkAR2HQx
889	War Over Land	174068	6so7pMCIBIBytE0JhgFBO1
892	內戰	27647	236Sw5jtGz9hu4r1LFwB5b
894	The 1st Amendment	80934	52htNzgWsWqwPuRmPbuJeb
895	You will always lose money chasing women, but you will never lose women chasing money	118865	1Q1dPQyKR3URw2Rv6xlhUy
896	Tell Me (U Want It)	213250	2fIv98BZ6NdkeYLZAvNzP7
898	Hollywood Forever	294857	3TpzJRU45jUPloLx6LKWcj
900	Innuendo (I Get U)	208378	1D84CoKziCbQw6NWVxorq4
902	Do It	213145	4BBL8YQ1SUhSbcsEguX8kL
904	Wish U Well	261263	0ny6sr26ROicSIpAatlVAP
907	PRETTY PRIVILEGE	194742	2iapoJmhpXu3QdKJ80V1rd
909	EVEN IF I TRIED	205374	2HYAx8W3oTlu5PCClBvgh5
912	I MAKE IT LOOK EFFORTLESS	67996	6zqceHCbmghjJ3Lvnm564U
914	GUESS WHO?	184346	15xfW2ms3DA45m5aHv0Wds
915	UNDER MY SKIN	156682	4bEvMIEWoAdzKJw6xs1GeY
916	BEING YOURSELF	185547	52pGVmSPSMHGFfoTavCv6p
917	U TRIED THAT THING WHERE UR HUMAN	283977	7wFo5aWDI2HKjzDOauEs5D
919	TEXAS BLUE	323840	1LLgtfY4umP78sh5LmyVpW
924	Head first	153224	4IFHV2mUjtQhT5EUOgBgZR
926	Bloodbath (Dance)	170937	5qM5ldkDmlDnBNOsp9YSrj
928	Aired out	188962	2Tu8F5S1Y6UCRunCRkeLex
929	You ruined it	135528	3zoEIwB7ElZs6BFuFHdiuJ
933	your clothes	254657	5gFfE8UgFslvqjVQw7dktZ
934	misplace	233783	0ALXVfQFaNZ1GmqvlG8X7V
935	pretender	221458	44auFUrGECh2dOIWHyGZyl
937	buzzcut, daisy	150502	1IHWMSs40XqfjcEc5JN9UQ
938	movies for guys	345796	1urgZoAjz91vFqPEokA1OR
939	kodak moment	367134	1OM5kosmreVYutffduC3kW
940	can you tell?	208739	2ODOdaX4ZqhqvnigNY3nSB
941	how to lie	225419	3mPk0eckjHFr7Q6L0M8dt9
942	champ	376836	0yMHRbPsUO7niNMiQidYSj
943	eyes off the wheel, i'm a star	233950	3VNUkBYUrUIjtyFfBSMaLq
944	let's go home	332563	7iR0pr6t3R9KBSCYoTHoVx
945	The Introduction	19820	5aeOEJVpGKxlzOQwpSKqcP
946	H-Town	184981	6UsYsmYnfzpIcTR0oqaQVw
947	Copy	163243	1WHPZGkvLpTeJ08LS9IMP3
948	Danny’s Track	52536	1ycWao0WR8QbrU060okPfd
949	Yoko Ono	179629	4188gCyHwTu6qteSnus4OF
950	NOLA	191170	1VK4zgMCkTKHMXCgPcj3tz
951	Post Break Up Beauty	172666	4drCFK6JgBFzJelxuLpRko
952	97 Jag	169344	6sttoqV8pbvwqL4VyLFZ4K
953	Text Me	146993	2RNvC0LEYaPRmV1TnNiOl0
954	Geezer	169776	76jsGLoaUN5kgYglcACpvC
955	I Wasn’t There	127888	0GT98Z4TvJJlrPwhxnaIzA
956	Blush Interlude	88625	5sFx7PwBeHilwy2KjL1W1o
957	Maroon	209830	6lJxjmUZ0EcZoxyKNhOOGa
958	Pop Out	201049	18WNTTWO3r2FP5T8R2RuVM
959	Doggy	172359	1fyw1dk1je16mWZ62OyaSu
960	Girlfriend	182571	6voUB02gkVXfqYdGnOJQPq
961	Bloom	126320	34oHS9iDgCrgJZedjtB9t6
964	NO QUESTIONS ASKED	359838	1OzmA3aBR7QK94L2tReAeD
968	AT A TIME LIKE THIS	276881	7tJ8jCSe5XPIkRluGfZTu3
971	THAT'S WHY	269475	35CL23NpSaz8lM9CVvg8Oq
972	I DREAM ABOUT SINKING	234549	1Pl6WfpPcicGFAlaQZoQcJ
973	NATURAL CAUSES	229742	223cxDEAew5PyufKXOX8Hg
974	THUNDRRR	280076	4xMXf0RP0AOdHHBpJ3b1F1
975	THE GREAT BAKUNAWA (with Danny Brown)	340098	6h9dDQDCFspMTxHREwn2pu
977	CASPER (with Maruja)	454015	40bqzt6BEkLetWWRWPl8kU
978	TWICE REMOVED	239161	6cMaeMxUUtPGZri4qPSQ5Y
979	Psychoboost	244844	7BMSBNctr9IPelr6MFvuRL
981	Experimental Skin	300445	5pt8I0fp9O0nhdIs3GgEBo
982	angels in camo	221544	7a4dV5aM4pHsTdOkqIVK8l
983	Dreamflasher	224486	75Wgg4LerPD3mVO5hEyUN9
984	TURN UP OR DIE	281713	2WlpEpIyQWh9xvLY598sZk
985	Dancing with your eyes closed	230526	1XD4K4CGAKTIBmFpvuaFru
987	Professional Vengeance	236571	2AjTT2CBthpsIQtyxzhSr4
989	JRJRJR	268803	29M6802gdnONhtdsjPdtv9
990	Doorway	174427	6jSdPCPsSI6ZBFzLluYVlh
992	Rewind	137463	5dO7SoTU75M2UVVmPKx1kv
993	Shady	107258	1mJaFzbwooFSNqvsHTCTe2
994	Dior	212949	3qvJiQOb5Qa0jO7MdLoBp3
995	Paris	62681	5bJqYSNRkEnbG44xrHjPtE
996	Cradle	144204	3tqnnQ0qHAt95ncZsMPARY
997	Upside Down	103883	3bXd3WMvXsBttyW74xgLXf
998	Guts	185389	0oQBABmTsY31O6GdEdmmV0
1000	DMT	140117	4vKQV5PL5wbzjryEOHfGhr
1001	Play my guitar	210211	2ivXSSVfpv2YUYMqX9x426
1004	Guesthouse	238865	4vfqKKWYFijdCGVwZkExyd
1005	Spider	258544	7iwljlEEmvOIurvOyUTTFL
1007	Something has to change	199652	4L0PTCqqCzoeZPHvVqPCEg
1008	Dead forever	243645	7l27Ygwdjprj2cZp8VJpZq
1010	Sick / relapse	322167	6YCEnfpx97ytWWpaOckZdz
1012	Halloween	217891	3sJhGM4YEVB9ESNEYkHAW2
1013	Sister	271676	0nmwzXWcQ7811lhoYdNCWk
1015	Bye Storm	220812	7s4sYkhBtHniPIa7woVWXp
1016	Perfectly Cut Scream	122409	03vipnCxcuvAexUUcY1MSM
1017	Like Me	140721	7btjEjaMb2lPynWEa34Fbj
1018	123	88528	6JDvvigEkWW9Zsps71kgdn
1021	Lifespan	123585	5fqUPNZKO1BUhxBN0H61Lx
1022	Who I Am	91088	65wAjSRDVNf3xtZYiZx7HY
1023	BULLKILLER	178706	1mwCqlYD8HL3IHuQ7fxrtk
1024	BOUNCE WIT ME	132040	416Ta5PKLxbthR4Bm8Zene
1025	DOOR SWANGIN	134680	2LXhy9FXWndD3JZnkYuOOy
1026	WHATUWANNASAY?!	203000	1GBMDAAXFiZxfmnFk4rM7Y
1027	CITGO	180400	6hi6mxHrFH1txKD5N42EJh
1028	JUNKYARD FREESTYLE	144600	1bnJBjf3L273p3bw2N1D1s
1029	BREAK TIME (feat. SMJ)	171973	6pS6dvlOMPsFOmbNiedGCi
1030	HERE II STAY (interlude)	151360	1uwE9XFquk7e5kjYHDuOH5
1031	TEST ME (feat. JID)	256866	7DHS2ac4HjmfLUjo9hbva9
1033	STREET CAR	204373	5Skc8z4Za820gV9UGTheV9
1034	BLACK FIT	167133	0M59Ojt1Exyn7VOURwDGjK
1035	COME TRUE	221000	0k5eMkkPsbSJyq6rngs51M
1036	FIND GOD (feat. Dominic Fike)	239120	51RDaTRAEHSitpeucJiHyU
1037	7ELEVEN	249760	28QvVEETJu1lauVSruQZsm
1038	Can I Have You For Myself?	321000	0voef3sKYAKr5BgUDCXIuW
1039	Dead Weight	268357	2ZHALGLudOZWRLuOK4MZ0J
1040	Grapefruit	260869	3Qd6Z4hclP1euAFfI1RQfK
1042	Zig Zag	416325	6lbeLrYmpDNrcAC25cxU0s
1043	Best Interest	268448	0YzFQAxFMx5qzUemP7bK0W
1044	Double Trio 2	310540	7jEz8Td0vLSRewFqwzkXPg
1045	And I Dance	259776	2rbJiY6ghr3dwFY4ICdFIR
1046	GGG	242362	67413j4i5YrPN0xy82kRKZ
1047	Cops and robbers	265959	4xmN2kN5mO7GexEr7Yo6d5
1048	Locals (Girls like us) [with gabby start]	258084	42FM6tM3n06euZCvpJn3dn
1050	You don't even know who I am	244022	4llQ1xFQfJyCLPnzVAImVw
1051	Johnny johnny johnny	245122	2nVs0rD57nLb69ExMQxNw2
1052	Shoot to kill, kill your darlings	304410	0WncF4YJaLcFIFAuBB4Hjn
1053	Horror movie soundtrack	232435	37htBb9BuEmj9Zu8xr8FLr
1054	Old money bitch	245857	4wfXA6UBjwkyoNFsnkKUEV
1055	Geez louise (with henhouse!)	440904	75oFbuRrKgPMf4nYnRLcXk
1056	Seventyseven dog years	275127	68qh6WgWbcS5TvmMbVU6ro
1057	Uncanny long arms (with Jane Remover)	326530	3jC2Ic2TzkF9MA7C3y6SDi
1058	Good luck final girl	208748	3k3JgTgVQS2UFEzoEjPrTW
1059	NO QUESTIONS ASKED	359838	2pXYDcWBarGyMAnb5lzKkK
1060	WAGING WAR (feat. Olēka)	315182	3zUlx7J1irZaYel4tU9qll
1061	LEARNING TO SWIM	290000	0tKZl6SbC0qLaMQWhBILxg
1062	RUIN MY LIFE	281000	0xntTakISl5ogVozRC8xo2
1063	GODSTAINED	205244	1LbW87aTWbwCdn1ZCTwg6Y
1064	AT A TIME LIKE THIS	276881	3KK8noas0aCsjkKM2d4lbR
1065	MONDAY	243664	5NtTgySRb3vO8Hl6hAiHHx
1066	DANCING WITHOUT MOVING	199403	5SskVOVWz80zhnW89UD07q
1067	THAT'S WHY	269475	0FzjG80gTUfhwLIZJS9s4e
1068	I DREAM ABOUT SINKING	234549	7r4GRO41L0wXxtX517bD1z
1069	NATURAL CAUSES	229742	1JgKOENf1Lu6okHg3zOawY
1070	THUNDRRR	280076	170pCc2ndNaWAaxY1rI5Ex
1071	THE GREAT BAKUNAWA (with Danny Brown)	340098	4SweX76iW04oBKMMcle66z
1073	FORGONE	474662	5R8rdwKrlSBZq4KiqxbcjM
1074	CASPER (with Maruja)	454015	5GV3XzTMQftMmRjbxhhPqM
1075	i. finale	431103	4wmNXY7vf3Zc1k1Q0rdHeD
1076	ii. à noite	466148	6q9viAYuJznGpexLuG8TXk
1077	iii. accordion's remorse	479972	3nwJjTphObeWha3DY3BpNy
1079	52 blue mondays	201378	3CRkzBsrkSbiqu5jLtzKDV
1080	woodside gardens 16 december 2012	158763	6ICgeUxGO0I9s7al8Xaint
1081	seventeen	240000	04kROJSP2it0owa7TnB4gH
1083	Bass	195506	3tynJ5xl3ZjRj2fPQF0kNi
1133	Palace	162960	5iozkhSH9ZyOupcJvXfSL0
1134	Peso	169560	3tTpvK7QgjjQCKGnHt5xn3
1136	Wassup	158133	1bjTEsJdDdbuA5JsdRRxhP
1137	Brand New Guy (feat. ScHoolboy Q)	288013	6haTrice1PU59Kd7esp3w1
1138	Purple Swag	118346	2mv7mXr45Mq9aOczaGCAbG
1139	Get Lit (feat. Fat Tony)	178706	4nzmPINOWf5sdKNrTjcM3z
1140	Trilla (feat. A$AP Nast & A$AP Twelvyy)	244160	3DtOW3gzNTy5SgLWhwOdFW
1141	Keep It G (feat. Chace Infinite & SpaceGhostPurrp)	230933	7kOsXY7jOOoa5hla5KcRAY
1142	Houston Old Head	258092	6lmMjq57ysbPyknJZjKuWI
1143	Acid Drip	123426	7zBgjx7pdhCR8v4v7oWT1I
1144	Leaf (feat. Main Attrakionz)	283240	1StRJBkcyMbf07b5TQRwYM
1145	Roll One Up	160440	2mUyRUNLHEPFflumWGuHyA
1146	Demons	180066	3Z6RaTSHc5PrpQL3DcvGW4
1147	Sandman	200160	0qkA0NU7cDKWkFXNGRcNaB
1249	don't mind me	309186	03xeviJQUuCTN3VRl8GI8j
1250	the memories we lost in translation	102746	1b429FwlKvnGFRIhSRn8XO
1251	born yesterday	361066	4QGSuTmh4PxESQxz1zbLmx
1252	picking up hands	299413	2xierjLR7uw06LgO6eETwN
1254	tell me a joke	304613	2fOYcnUo9iPTOqIlSg26MY
1255	sorry4dying	284786	1ljziaoMnRH95aPeOSGAtr
1304	house settling	292893	10zPOOHRblprd5uilHAXuC
1305	knots	251853	2K3GVvfPSkFj5ZxjyCVmum
1306	fantasyworld	438160	3VheddjCE7GCHzeKIJnRzK
1307	fractions of infinity	323453	3WmKRujdLPLKQhOlf6qHTY
1308	cassini's division	496080	1eb55iDkYFqbPQ3dDWSUjv
\.


--
-- Data for Name: songs_artists; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.songs_artists (song_id, artist_id, artist_role) FROM stdin;
1	1	primary artist
2	2	primary artist
4	4	primary artist
7	10	primary artist
11	18	primary artist
12	20	primary artist
15	4	primary artist
20	10	primary artist
21	38	primary artist
27	50	primary artist
35	66	primary artist
35	4	primary artist
44	4	primary artist
64	20	primary artist
65	38	primary artist
66	4	primary artist
66	133	primary artist
67	50	primary artist
68	10	primary artist
69	138	primary artist
70	140	primary artist
81	10	primary artist
82	18	primary artist
100	50	primary artist
101	4	primary artist
142	292	primary artist
142	4	primary artist
164	38	primary artist
187	10	primary artist
187	391	primary artist
188	4	primary artist
189	394	primary artist
213	50	primary artist
240	4	primary artist
241	140	primary artist
242	50	primary artist
243	10	primary artist
244	138	primary artist
245	4	primary artist
245	18	primary artist
246	38	primary artist
247	520	primary artist
247	521	primary artist
275	4	primary artist
276	10	primary artist
278	589	primary artist
279	4	primary artist
280	4	primary artist
281	50	primary artist
282	10	primary artist
283	599	primary artist
283	601	primary artist
284	38	primary artist
320	589	primary artist
325	520	primary artist
325	521	primary artist
327	4	primary artist
328	38	primary artist
329	140	primary artist
330	20	primary artist
331	10	primary artist
332	4	primary artist
333	66	primary artist
333	4	primary artist
333	713	primary artist
334	38	primary artist
335	140	primary artist
336	20	primary artist
337	4	primary artist
338	10	primary artist
339	50	primary artist
339	38	primary artist
340	38	primary artist
341	140	primary artist
342	20	primary artist
570	4	primary artist
670	10	primary artist
720	1572	primary artist
871	10	primary artist
872	10	primary artist
874	10	primary artist
876	10	primary artist
877	10	primary artist
878	10	primary artist
880	10	primary artist
881	10	primary artist
885	10	primary artist
888	10	primary artist
889	10	primary artist
892	10	primary artist
894	10	primary artist
895	10	primary artist
896	20	primary artist
898	20	primary artist
900	20	primary artist
902	20	primary artist
904	20	primary artist
907	4	primary artist
909	4	primary artist
912	4	primary artist
914	4	primary artist
915	4	primary artist
916	4	primary artist
917	4	primary artist
919	4	primary artist
919	66	primary artist
924	38	primary artist
926	38	primary artist
928	38	primary artist
929	38	primary artist
933	50	primary artist
934	50	primary artist
935	50	primary artist
937	50	primary artist
938	50	primary artist
939	50	primary artist
940	50	primary artist
941	50	primary artist
942	50	primary artist
943	50	primary artist
944	50	primary artist
945	66	primary artist
945	1981	primary artist
946	66	primary artist
946	1983	primary artist
946	713	primary artist
946	1985	primary artist
947	66	primary artist
947	1987	primary artist
947	1983	primary artist
947	1985	primary artist
948	66	primary artist
948	1991	primary artist
949	66	primary artist
949	1985	primary artist
949	1994	primary artist
950	66	primary artist
950	1996	primary artist
950	1985	primary artist
950	1998	primary artist
950	1999	primary artist
950	10	primary artist
950	713	primary artist
950	4	primary artist
951	66	primary artist
951	1985	primary artist
952	66	primary artist
952	1985	primary artist
953	66	primary artist
953	2008	primary artist
954	66	primary artist
954	2010	primary artist
954	2011	primary artist
955	66	primary artist
955	2013	primary artist
956	66	primary artist
957	66	primary artist
957	2010	primary artist
958	66	primary artist
958	713	primary artist
958	1999	primary artist
958	1987	primary artist
958	2021	primary artist
958	1985	primary artist
959	2011	primary artist
959	66	primary artist
959	2010	primary artist
959	1985	primary artist
959	1996	primary artist
960	66	primary artist
960	1999	primary artist
960	1985	primary artist
960	1996	primary artist
961	66	primary artist
961	1985	primary artist
961	713	primary artist
964	4	primary artist
968	4	primary artist
971	4	primary artist
972	4	primary artist
973	4	primary artist
974	4	primary artist
975	4	primary artist
975	1991	primary artist
977	4	primary artist
977	2056	primary artist
978	50	primary artist
979	50	primary artist
979	1991	primary artist
981	50	primary artist
982	50	primary artist
983	50	primary artist
984	50	primary artist
985	50	primary artist
987	50	primary artist
989	50	primary artist
990	138	primary artist
992	138	primary artist
993	138	primary artist
994	138	primary artist
995	138	primary artist
996	138	primary artist
997	138	primary artist
998	138	primary artist
1000	138	primary artist
1001	140	primary artist
1004	140	primary artist
1005	140	primary artist
1007	140	primary artist
1008	140	primary artist
1010	140	primary artist
1012	140	primary artist
1013	140	primary artist
1015	521	primary artist
1016	589	primary artist
1017	589	primary artist
1018	589	primary artist
1021	589	primary artist
1022	589	primary artist
1023	599	primary artist
1024	599	primary artist
1025	599	primary artist
1026	599	primary artist
1027	599	primary artist
1028	599	primary artist
1029	599	primary artist
1029	2111	primary artist
1030	599	primary artist
1031	599	primary artist
1031	2114	primary artist
1033	599	primary artist
1034	599	primary artist
1035	599	primary artist
1036	599	primary artist
1036	2010	primary artist
1037	599	primary artist
1038	520	primary artist
1038	521	primary artist
1039	520	primary artist
1039	521	primary artist
1040	520	primary artist
1040	521	primary artist
1042	520	primary artist
1042	521	primary artist
1043	520	primary artist
1043	521	primary artist
1043	2135	primary artist
1044	520	primary artist
1044	521	primary artist
1045	520	primary artist
1045	521	primary artist
1046	520	primary artist
1046	521	primary artist
1047	20	primary artist
1048	20	primary artist
1048	2144	primary artist
1050	20	primary artist
1051	20	primary artist
1052	20	primary artist
1053	20	primary artist
1054	20	primary artist
1055	20	primary artist
1055	2152	primary artist
1056	20	primary artist
1057	20	primary artist
1057	50	primary artist
1058	20	primary artist
1059	4	primary artist
1060	4	primary artist
1060	18	primary artist
1061	4	primary artist
1062	4	primary artist
1063	4	primary artist
1064	4	primary artist
1065	4	primary artist
1066	4	primary artist
1067	4	primary artist
1068	4	primary artist
1069	4	primary artist
1070	4	primary artist
1071	4	primary artist
1071	1991	primary artist
1073	4	primary artist
1074	4	primary artist
1074	2056	primary artist
1075	4	primary artist
1076	4	primary artist
1077	4	primary artist
1079	50	primary artist
1080	50	primary artist
1081	50	primary artist
1083	2185	primary artist
1133	2185	primary artist
1134	2185	primary artist
1136	2185	primary artist
1137	2185	primary artist
1137	2299	primary artist
1138	2185	primary artist
1139	2185	primary artist
1139	2302	primary artist
1140	2185	primary artist
1140	2304	primary artist
1140	2305	primary artist
1141	2185	primary artist
1141	2307	primary artist
1141	2308	primary artist
1142	2185	primary artist
1143	2185	primary artist
1144	2185	primary artist
1144	2312	primary artist
1145	2185	primary artist
1146	2185	primary artist
1147	2185	primary artist
1249	4	primary artist
1250	4	primary artist
1251	4	primary artist
1252	4	primary artist
1254	4	primary artist
1255	4	primary artist
1304	4	primary artist
1304	1991	primary artist
1305	4	primary artist
1306	4	primary artist
1307	4	primary artist
1307	2646	primary artist
1308	4	primary artist
1308	2648	primary artist
\.


--
-- Data for Name: songs_genres; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.songs_genres (song_id, genre_id) FROM stdin;
1	3
2	2
\.


--
-- Data for Name: songs_releases; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.songs_releases (song_id, release_id, added_date, removed_date) FROM stdin;
1	1	2026-05-29 17:54:33.791661	\N
2	2	2026-05-29 17:54:33.791661	\N
4	4	2026-05-31 13:11:27.491382	\N
7	7	2026-05-31 13:17:02.450352	\N
11	11	2026-05-31 13:21:43.448764	\N
12	12	2026-05-31 13:21:43.460869	\N
15	15	2026-05-31 13:22:56.959535	\N
20	7	2026-05-31 13:30:36.702194	\N
21	21	2026-05-31 13:30:36.72474	\N
27	27	2026-05-31 13:33:42.738688	\N
35	35	2026-05-31 13:35:24.065871	\N
44	44	2026-05-31 13:39:02.669568	\N
64	12	2026-05-31 14:03:37.592456	\N
65	21	2026-05-31 14:03:37.620125	\N
66	15	2026-05-31 14:03:37.626722	\N
67	67	2026-05-31 14:03:37.635441	\N
68	7	2026-05-31 14:03:37.643124	\N
69	69	2026-05-31 14:03:37.650058	\N
70	70	2026-05-31 14:03:37.657087	\N
81	7	2026-05-31 14:09:11.746126	\N
82	11	2026-05-31 14:09:11.770928	\N
100	100	2026-05-31 14:23:16.876171	\N
101	44	2026-05-31 14:23:16.895919	\N
142	142	2026-05-31 14:27:56.564604	\N
164	21	2026-05-31 14:31:12.067763	\N
187	7	2026-05-31 14:40:44.702604	\N
188	15	2026-05-31 14:40:44.732537	\N
189	189	2026-05-31 14:40:44.745588	\N
213	67	2026-05-31 14:41:41.531697	\N
240	15	2026-05-31 15:12:02.759118	\N
241	70	2026-05-31 15:12:02.792937	\N
242	67	2026-05-31 15:12:02.806005	\N
243	7	2026-05-31 15:12:02.818757	\N
244	69	2026-05-31 15:12:02.826044	\N
245	44	2026-05-31 15:12:02.835289	\N
246	21	2026-05-31 15:12:02.848015	\N
247	247	2026-05-31 15:12:02.855621	\N
275	44	2026-05-31 16:31:41.775761	\N
276	7	2026-05-31 16:31:41.81309	\N
278	278	2026-05-31 16:31:41.837652	\N
279	15	2026-05-31 16:31:41.853572	\N
280	44	2026-05-31 16:31:41.866786	\N
281	27	2026-05-31 16:31:41.873037	\N
282	7	2026-05-31 16:31:41.88508	\N
283	283	2026-05-31 16:31:41.896954	\N
284	21	2026-05-31 16:31:41.917502	\N
320	278	2026-05-31 20:42:48.420195	\N
325	325	2026-05-31 20:42:48.503817	\N
327	44	2026-05-31 20:42:48.533574	\N
328	21	2026-05-31 20:42:48.542713	\N
329	70	2026-05-31 20:42:48.557682	\N
330	12	2026-05-31 20:42:48.569015	\N
331	7	2026-05-31 20:42:48.577143	\N
332	15	2026-05-31 20:42:48.58707	\N
333	35	2026-05-31 20:42:48.597632	\N
334	21	2026-05-31 20:42:48.612192	\N
335	70	2026-05-31 20:42:48.624066	\N
336	336	2026-05-31 20:42:48.631499	\N
337	337	2026-05-31 20:42:48.636122	\N
338	7	2026-05-31 20:42:48.639292	\N
339	339	2026-05-31 20:42:48.642373	\N
340	21	2026-05-31 20:42:48.645315	\N
341	70	2026-05-31 20:42:48.649115	\N
342	12	2026-05-31 20:42:48.652231	\N
570	15	2026-05-31 21:00:19.244719	\N
670	7	2026-05-31 21:05:30.979399	\N
720	720	2026-05-31 21:06:03.070987	\N
871	7	2026-05-31 21:06:31.797043	\N
872	7	2026-05-31 21:06:31.862209	\N
874	7	2026-05-31 21:06:31.974662	\N
876	7	2026-05-31 21:06:32.090332	\N
877	7	2026-05-31 21:06:32.14707	\N
878	7	2026-05-31 21:06:32.205192	\N
880	7	2026-05-31 21:06:32.31861	\N
881	7	2026-05-31 21:06:32.375599	\N
885	7	2026-05-31 21:06:32.602465	\N
888	7	2026-05-31 21:06:32.781859	\N
889	7	2026-05-31 21:06:32.83927	\N
892	7	2026-05-31 21:06:33.017038	\N
894	7	2026-05-31 21:06:33.130153	\N
895	7	2026-05-31 21:06:33.186021	\N
896	12	2026-05-31 21:06:33.411874	\N
898	12	2026-05-31 21:06:33.526045	\N
900	12	2026-05-31 21:06:33.638655	\N
902	12	2026-05-31 21:06:33.753359	\N
904	12	2026-05-31 21:06:33.865098	\N
907	15	2026-05-31 21:06:34.476005	\N
909	15	2026-05-31 21:06:34.5916	\N
912	15	2026-05-31 21:06:34.763976	\N
914	15	2026-05-31 21:06:34.878994	\N
915	15	2026-05-31 21:06:34.934552	\N
916	15	2026-05-31 21:06:34.991276	\N
917	15	2026-05-31 21:06:35.049465	\N
919	15	2026-05-31 21:06:35.163339	\N
924	21	2026-05-31 21:06:35.637386	\N
926	21	2026-05-31 21:06:35.752814	\N
928	21	2026-05-31 21:06:35.867541	\N
929	21	2026-05-31 21:06:35.923816	\N
933	27	2026-05-31 21:06:36.40191	\N
934	27	2026-05-31 21:06:36.457775	\N
935	27	2026-05-31 21:06:36.516132	\N
937	27	2026-05-31 21:06:36.630035	\N
938	27	2026-05-31 21:06:36.687554	\N
939	27	2026-05-31 21:06:36.743287	\N
940	27	2026-05-31 21:06:36.797807	\N
941	27	2026-05-31 21:06:36.856722	\N
942	27	2026-05-31 21:06:36.911253	\N
943	27	2026-05-31 21:06:36.966918	\N
944	27	2026-05-31 21:06:37.024024	\N
945	35	2026-05-31 21:06:37.243571	\N
946	35	2026-05-31 21:06:37.302427	\N
947	35	2026-05-31 21:06:37.365044	\N
948	35	2026-05-31 21:06:37.422519	\N
949	35	2026-05-31 21:06:37.481342	\N
950	35	2026-05-31 21:06:37.54037	\N
951	35	2026-05-31 21:06:37.608254	\N
952	35	2026-05-31 21:06:37.666254	\N
953	35	2026-05-31 21:06:37.727585	\N
954	35	2026-05-31 21:06:37.790549	\N
955	35	2026-05-31 21:06:37.848928	\N
956	35	2026-05-31 21:06:37.905501	\N
957	35	2026-05-31 21:06:37.961484	\N
958	35	2026-05-31 21:06:38.020083	\N
959	35	2026-05-31 21:06:38.086851	\N
960	35	2026-05-31 21:06:38.150046	\N
961	35	2026-05-31 21:06:38.208092	\N
964	44	2026-05-31 21:06:38.559047	\N
968	44	2026-05-31 21:06:38.788231	\N
971	44	2026-05-31 21:06:38.957017	\N
972	44	2026-05-31 21:06:39.011248	\N
973	44	2026-05-31 21:06:39.0682	\N
974	44	2026-05-31 21:06:39.125292	\N
975	44	2026-05-31 21:06:39.18256	\N
977	44	2026-05-31 21:06:39.299123	\N
978	67	2026-05-31 21:06:39.557842	\N
979	67	2026-05-31 21:06:39.613548	\N
981	67	2026-05-31 21:06:39.729092	\N
982	67	2026-05-31 21:06:39.787775	\N
983	67	2026-05-31 21:06:39.846101	\N
984	67	2026-05-31 21:06:39.900618	\N
985	67	2026-05-31 21:06:39.956169	\N
987	67	2026-05-31 21:06:40.071985	\N
989	67	2026-05-31 21:06:40.182744	\N
990	69	2026-05-31 21:06:40.384982	\N
992	69	2026-05-31 21:06:40.498716	\N
993	69	2026-05-31 21:06:40.55607	\N
994	69	2026-05-31 21:06:40.612352	\N
995	69	2026-05-31 21:06:40.670477	\N
996	69	2026-05-31 21:06:40.727535	\N
997	69	2026-05-31 21:06:40.784212	\N
998	69	2026-05-31 21:06:40.839808	\N
1000	69	2026-05-31 21:06:40.971773	\N
1001	70	2026-05-31 21:06:41.146691	\N
1004	70	2026-05-31 21:06:41.319235	\N
1005	70	2026-05-31 21:06:41.375915	\N
1007	70	2026-05-31 21:06:41.490829	\N
1008	70	2026-05-31 21:06:41.548106	\N
1010	70	2026-05-31 21:06:41.660245	\N
1012	70	2026-05-31 21:06:41.773479	\N
1013	70	2026-05-31 21:06:41.831341	\N
1015	247	2026-05-31 21:06:42.140565	\N
1016	278	2026-05-31 21:06:42.361452	\N
1017	278	2026-05-31 21:06:42.417261	\N
1018	278	2026-05-31 21:06:42.473988	\N
1021	278	2026-05-31 21:06:42.645609	\N
1022	278	2026-05-31 21:06:42.704701	\N
1023	283	2026-05-31 21:06:42.913032	\N
1024	283	2026-05-31 21:06:42.969928	\N
1025	283	2026-05-31 21:06:43.025759	\N
1026	283	2026-05-31 21:06:43.083614	\N
1027	283	2026-05-31 21:06:43.141046	\N
1028	283	2026-05-31 21:06:43.199068	\N
1029	283	2026-05-31 21:06:43.256059	\N
1030	283	2026-05-31 21:06:43.31376	\N
1031	283	2026-05-31 21:06:43.370408	\N
1033	283	2026-05-31 21:06:43.493163	\N
1034	283	2026-05-31 21:06:43.551869	\N
1035	283	2026-05-31 21:06:43.608364	\N
1036	283	2026-05-31 21:06:43.666076	\N
1037	283	2026-05-31 21:06:43.72378	\N
1038	325	2026-05-31 21:06:43.981971	\N
1039	325	2026-05-31 21:06:44.041332	\N
1040	325	2026-05-31 21:06:44.099492	\N
1042	325	2026-05-31 21:06:44.213945	\N
1043	325	2026-05-31 21:06:44.272471	\N
1044	325	2026-05-31 21:06:44.333773	\N
1045	325	2026-05-31 21:06:44.391802	\N
1046	325	2026-05-31 21:06:44.448922	\N
1047	336	2026-05-31 21:06:44.666003	\N
1048	336	2026-05-31 21:06:44.722524	\N
1050	336	2026-05-31 21:06:44.837593	\N
1051	336	2026-05-31 21:06:44.892706	\N
1052	336	2026-05-31 21:06:44.949488	\N
1053	336	2026-05-31 21:06:45.005819	\N
1054	336	2026-05-31 21:06:45.06249	\N
1055	336	2026-05-31 21:06:45.118959	\N
1056	336	2026-05-31 21:06:45.174231	\N
1057	336	2026-05-31 21:06:45.228788	\N
1058	336	2026-05-31 21:06:45.287488	\N
1059	337	2026-05-31 21:06:45.457213	\N
1060	337	2026-05-31 21:06:45.512813	\N
1061	337	2026-05-31 21:06:45.570599	\N
1062	337	2026-05-31 21:06:45.6268	\N
1063	337	2026-05-31 21:06:45.683359	\N
1064	337	2026-05-31 21:06:45.739356	\N
1065	337	2026-05-31 21:06:45.795716	\N
1066	337	2026-05-31 21:06:45.852314	\N
1067	337	2026-05-31 21:06:45.90814	\N
1068	337	2026-05-31 21:06:45.963531	\N
1069	337	2026-05-31 21:06:46.021346	\N
1070	337	2026-05-31 21:06:46.079399	\N
1071	337	2026-05-31 21:06:46.140064	\N
1073	337	2026-05-31 21:06:46.256825	\N
1074	337	2026-05-31 21:06:46.313876	\N
1075	337	2026-05-31 21:06:46.372265	\N
1076	337	2026-05-31 21:06:46.430289	\N
1077	337	2026-05-31 21:06:46.487834	\N
1079	339	2026-05-31 21:06:46.728358	\N
1080	339	2026-05-31 21:06:46.785282	\N
1081	339	2026-05-31 21:06:46.841396	\N
1083	870	2026-05-31 21:56:14.326135	\N
1133	870	2026-05-31 21:56:14.771574	\N
1134	870	2026-05-31 21:56:14.827809	\N
1136	870	2026-05-31 21:56:14.940221	\N
1137	870	2026-05-31 21:56:15.01288	\N
1138	870	2026-05-31 21:56:15.07757	\N
1139	870	2026-05-31 21:56:15.134181	\N
1140	870	2026-05-31 21:56:15.192616	\N
1141	870	2026-05-31 21:56:15.256101	\N
1142	870	2026-05-31 21:56:15.313815	\N
1143	870	2026-05-31 21:56:15.369355	\N
1144	870	2026-05-31 21:56:15.427112	\N
1145	870	2026-05-31 21:56:15.48471	\N
1146	870	2026-05-31 21:56:15.540965	\N
1147	870	2026-05-31 21:56:15.596265	\N
1249	1021	2026-06-01 14:50:33.931182	\N
1250	1021	2026-06-01 14:50:33.956122	\N
1251	1021	2026-06-01 14:50:33.965563	\N
1252	1021	2026-06-01 14:50:33.975744	\N
1254	1021	2026-06-01 14:50:33.995171	\N
1255	1021	2026-06-01 14:50:34.00537	\N
1304	1021	2026-06-01 14:50:34.762527	\N
1305	1021	2026-06-01 14:50:34.818994	\N
1306	1021	2026-06-01 14:50:34.878652	\N
1307	1021	2026-06-01 14:50:34.934864	\N
1308	1021	2026-06-01 14:50:34.998339	\N
\.


--
-- Data for Name: streaming_accounts; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.streaming_accounts (user_id, streaming_id, access_token, refresh_token, token_expires_at) FROM stdin;
1	spotify_user_id_123	access_abc	refresh_xyz	2026-12-31 23:59:59
114	31qe4mgnwu3mcqrheuqavdcuzcyq	BQDKDjDac_PfFcj836DrvxaWux6mOQajgyU7CDfEJfyge2tZSAMWYBb03XksmjlvNbR7tXuWYyIuWlaFiFcz5oNPScpyrxcRNULyzD34TYTqZ5kjpB7UplRy9Ffp6cZEcEtnTMt5zjRAXl0uWMuOE6UQ4Ie2LbHZi9GWWSorp5JQCngF7yMKlCvYEBAaO9btYPtUem-FwokjLgapKIBIlyS0SUC-0crAbaWi_izG4c-dloDQQYTGnCcyfNI6JdkJTFQ_WNIWNg	AQAV7n_kmdOAtx26ZDqDB_4Ghr0WGB-lADSenPKci0qiWBQDjEdiOPg0aByG-x5eH5GFay1T8JEgL9qk2G1lU0DERwk7MXoy_TvHh3SwBhxBeYQnWDPa9swxoB9q7h-a6r4	2026-06-01 15:50:33.58
\.


--
-- Data for Name: streams; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.streams (id, song_id, user_id, stream_timestamp) FROM stdin;
1	1	1	2026-05-29 17:54:33.797487
3	4	114	2026-05-31 13:08:22.698
6	7	114	2026-05-31 13:15:26.632
10	11	114	2026-05-31 13:21:19.347
11	12	114	2026-05-31 13:21:00.781
14	15	114	2026-05-31 13:22:44.338
19	20	114	2026-05-31 13:27:21.676
20	21	114	2026-05-31 13:25:34.581
26	27	114	2026-05-31 13:32:20.382
34	35	114	2026-05-31 13:35:01.466
43	44	114	2026-05-31 13:38:27.232
63	64	114	2026-05-31 14:00:20.66
64	65	114	2026-05-31 13:56:52.849
65	66	114	2026-05-31 13:54:07.213
66	67	114	2026-05-31 13:51:04.752
67	68	114	2026-05-31 13:46:45.311
68	69	114	2026-05-31 13:43:31.093
69	70	114	2026-05-31 13:41:49.791
80	81	114	2026-05-31 14:07:59.841
81	82	114	2026-05-31 14:05:59.476
99	100	114	2026-05-31 14:21:16.115
100	101	114	2026-05-31 14:15:55.03
141	142	114	2026-05-31 14:25:23.341
163	164	114	2026-05-31 14:28:42.056
186	187	114	2026-05-31 14:37:56.17
187	188	114	2026-05-31 14:35:02.274
188	189	114	2026-05-31 14:31:32.439
212	213	114	2026-05-31 14:41:17.268
239	240	114	2026-05-31 15:10:28.487
240	241	114	2026-05-31 15:08:26.588
241	242	114	2026-05-31 15:04:46.912
242	243	114	2026-05-31 15:00:27.247
243	244	114	2026-05-31 14:58:30.617
244	245	114	2026-05-31 14:55:49.834
245	246	114	2026-05-31 14:50:34.123
246	247	114	2026-05-31 14:48:13.986
274	275	114	2026-05-31 16:31:25.874
275	276	114	2026-05-31 15:35:42.984
276	4	114	2026-05-31 15:33:46.123
277	278	114	2026-05-31 15:32:06.11
278	279	114	2026-05-31 15:29:21.815
279	280	114	2026-05-31 15:26:45.6
280	281	114	2026-05-31 15:23:25.685
281	282	114	2026-05-31 15:20:24.109
282	283	114	2026-05-31 15:17:20.825
283	284	114	2026-05-31 15:13:38.313
319	320	114	2026-05-31 18:47:06.197
320	278	114	2026-05-31 18:37:47.622
321	320	114	2026-05-31 18:34:14.105
322	320	114	2026-05-31 18:32:42.079
323	320	114	2026-05-31 17:47:08.573
324	325	114	2026-05-31 17:45:52.423
325	4	114	2026-05-31 17:45:36.533
326	327	114	2026-05-31 17:24:37.469
327	328	114	2026-05-31 17:19:55.115
328	329	114	2026-05-31 17:17:19.774
329	330	114	2026-05-31 17:13:58.802
330	331	114	2026-05-31 17:09:50.18
331	332	114	2026-05-31 17:07:17.549
332	333	114	2026-05-31 17:05:09.003
333	334	114	2026-05-31 17:01:59.981
334	335	114	2026-05-31 16:57:59.342
335	336	114	2026-05-31 16:53:43.199
336	337	114	2026-05-31 16:49:34.881
337	338	114	2026-05-31 16:45:57.613
338	339	114	2026-05-31 16:43:29.957
339	340	114	2026-05-31 16:41:04.258
340	341	114	2026-05-31 16:38:11.201
341	342	114	2026-05-31 16:34:15.901
369	320	114	2026-05-31 20:56:39.945
370	320	114	2026-05-31 20:55:07.958
469	320	114	2026-05-31 20:58:12.049
569	570	114	2026-05-31 21:00:08.985
570	320	114	2026-05-31 20:59:44.162
669	670	114	2026-05-31 21:03:16.194
719	720	114	2026-05-31 21:05:19.413
869	1083	114	2026-05-31 21:09:33.794
870	720	114	2026-05-31 21:06:17.762
969	4	114	2026-06-01 00:33:09.136
970	1022	114	2026-06-01 00:30:13.62
971	1021	114	2026-06-01 00:28:42.444
972	320	114	2026-06-01 00:26:38.934
973	278	114	2026-06-01 00:25:07.334
974	1018	114	2026-06-01 00:22:23.633
975	1017	114	2026-06-01 00:20:55.137
976	1016	114	2026-06-01 00:18:34.317
977	320	114	2026-06-01 00:16:32.273
978	1021	114	2026-06-01 00:16:22.854
1019	1077	114	2026-06-01 14:31:07.303
1020	1249	114	2026-06-01 14:23:06.802
1021	1250	114	2026-06-01 13:06:37.252
1022	1251	114	2026-06-01 13:04:54.594
1023	1252	114	2026-06-01 12:58:53.466
1024	1249	114	2026-06-01 12:53:54.05
1025	1254	114	2026-06-01 12:48:44.951
1026	1255	114	2026-06-01 12:43:40.296
1027	4	114	2026-06-01 12:14:43.446
1028	974	114	2026-06-01 12:11:27.218
1029	919	114	2026-06-01 02:47:02.385
1030	240	114	2026-06-01 02:41:38.477
1031	914	114	2026-06-01 02:39:36.754
1032	188	114	2026-06-01 02:36:31.949
1033	279	114	2026-06-01 02:33:02.612
1034	15	114	2026-06-01 02:30:27.642
\.


--
-- Data for Name: user_follows; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.user_follows (user_id, followed_user_id, date_from, date_until) FROM stdin;
2	1	2026-05-29 17:54:33.793998	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: schema_; Owner: -
--

COPY schema_.users (id, name, passwd, date_joined, date_left) FROM stdin;
1	meloman_99	zaszyfrowane_haslo_1	2026-05-29 17:54:33.788895	\N
2	techno_king	zaszyfrowane_haslo_2	2026-05-29 17:54:33.788895	\N
114	kubs	$2b$12$W8e5Uf1Byt6XzihBGmzoOusqsISySBZZzZreqKxBe8H.xB.kLC/hq	2026-05-31 12:43:49.726446	\N
\.


--
-- Name: artist_roles_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.artist_roles_id_seq', 1, true);


--
-- Name: artists_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.artists_id_seq', 2648, true);


--
-- Name: genres_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.genres_id_seq', 3, true);


--
-- Name: playlists_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.playlists_id_seq', 3, true);


--
-- Name: releases_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.releases_id_seq', 1069, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.reviews_id_seq', 10, true);


--
-- Name: songs_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.songs_id_seq', 1308, true);


--
-- Name: streams_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.streams_id_seq', 1068, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: schema_; Owner: -
--

SELECT pg_catalog.setval('schema_.users_id_seq', 115, true);


--
-- Name: artist_roles artist_roles_name_key; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artist_roles
    ADD CONSTRAINT artist_roles_name_key UNIQUE (name);


--
-- Name: artist_roles artist_roles_pkey; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artist_roles
    ADD CONSTRAINT artist_roles_pkey PRIMARY KEY (id);


--
-- Name: artists_releases artists_releases_pk; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artists_releases
    ADD CONSTRAINT artists_releases_pk PRIMARY KEY (artist_id, release_id, artist_role_id);


--
-- Name: artists artists_spotify_id_key; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artists
    ADD CONSTRAINT artists_spotify_id_key UNIQUE (spotify_id);


--
-- Name: artist_follows pk_artist_follows; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artist_follows
    ADD CONSTRAINT pk_artist_follows PRIMARY KEY (user_id, followed_artist_id, date_from);


--
-- Name: artists_aliases pk_artists_aliases; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artists_aliases
    ADD CONSTRAINT pk_artists_aliases PRIMARY KEY (artist_id, artist_alias);


--
-- Name: import_errors pk_import_errors; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.import_errors
    ADD CONSTRAINT pk_import_errors PRIMARY KEY (id);


--
-- Name: import_requests pk_import_requests; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.import_requests
    ADD CONSTRAINT pk_import_requests PRIMARY KEY (id);


--
-- Name: playlist_likes pk_playlist_likes; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_likes
    ADD CONSTRAINT pk_playlist_likes PRIMARY KEY (playlist_id, user_id, date_added);


--
-- Name: playlist_songs pk_playlist_songs; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_songs
    ADD CONSTRAINT pk_playlist_songs PRIMARY KEY (playlist_id, song_id, date_added);


--
-- Name: playlists pk_playlists; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlists
    ADD CONSTRAINT pk_playlists PRIMARY KEY (id);


--
-- Name: playlist_owners pk_playlists_owners; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_owners
    ADD CONSTRAINT pk_playlists_owners PRIMARY KEY (playlist_id, user_id);


--
-- Name: release_covers pk_release_covers; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.release_covers
    ADD CONSTRAINT pk_release_covers PRIMARY KEY (id);


--
-- Name: release_likes pk_release_likes; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.release_likes
    ADD CONSTRAINT pk_release_likes PRIMARY KEY (release_id, user_id, date_added);


--
-- Name: release_reviews pk_release_reviews; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.release_reviews
    ADD CONSTRAINT pk_release_reviews PRIMARY KEY (release_id, review_id);


--
-- Name: releases_genres pk_releases_genres; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.releases_genres
    ADD CONSTRAINT pk_releases_genres PRIMARY KEY (genre_id, release_id);


--
-- Name: song_likes pk_song_likes; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.song_likes
    ADD CONSTRAINT pk_song_likes PRIMARY KEY (user_id, song_id, date_added);


--
-- Name: reviews pk_song_reviews; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.reviews
    ADD CONSTRAINT pk_song_reviews PRIMARY KEY (id);


--
-- Name: song_reviews pk_song_reviews_0; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.song_reviews
    ADD CONSTRAINT pk_song_reviews_0 PRIMARY KEY (song_id, review_id);


--
-- Name: songs_artists pk_songs_artists; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_artists
    ADD CONSTRAINT pk_songs_artists PRIMARY KEY (song_id, artist_id, artist_role);


--
-- Name: songs_genres pk_songs_genres; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_genres
    ADD CONSTRAINT pk_songs_genres PRIMARY KEY (song_id, genre_id);


--
-- Name: songs_releases pk_songs_releases; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_releases
    ADD CONSTRAINT pk_songs_releases PRIMARY KEY (song_id, release_id, added_date);


--
-- Name: streaming_accounts pk_streaming_accounts; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.streaming_accounts
    ADD CONSTRAINT pk_streaming_accounts PRIMARY KEY (user_id);


--
-- Name: songs pk_tbl; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs
    ADD CONSTRAINT pk_tbl PRIMARY KEY (id);


--
-- Name: genres pk_tbl_0; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.genres
    ADD CONSTRAINT pk_tbl_0 PRIMARY KEY (id);


--
-- Name: releases pk_tbl_1; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.releases
    ADD CONSTRAINT pk_tbl_1 PRIMARY KEY (id);


--
-- Name: artists pk_tbl_2; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artists
    ADD CONSTRAINT pk_tbl_2 PRIMARY KEY (id);


--
-- Name: user_follows pk_user_follows; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.user_follows
    ADD CONSTRAINT pk_user_follows PRIMARY KEY (user_id, followed_user_id, date_from);


--
-- Name: users pk_users; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.users
    ADD CONSTRAINT pk_users PRIMARY KEY (id);


--
-- Name: releases releases_spotify_id_key; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.releases
    ADD CONSTRAINT releases_spotify_id_key UNIQUE (spotify_id);


--
-- Name: songs songs_spotify_id_key; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs
    ADD CONSTRAINT songs_spotify_id_key UNIQUE (spotify_id);


--
-- Name: streams streams_pk; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.streams
    ADD CONSTRAINT streams_pk PRIMARY KEY (song_id, user_id, stream_timestamp);


--
-- Name: streaming_accounts unq_streaming_accounts; Type: CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.streaming_accounts
    ADD CONSTRAINT unq_streaming_accounts UNIQUE (streaming_id);


--
-- Name: artist_follows_artist_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX artist_follows_artist_active_index ON schema_.artist_follows USING btree (followed_artist_id, user_id) WHERE (date_until IS NULL);


--
-- Name: artist_follows_user_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX artist_follows_user_active_index ON schema_.artist_follows USING btree (user_id) WHERE (date_until IS NULL);


--
-- Name: artists_releases_release_id_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX artists_releases_release_id_index ON schema_.artists_releases USING btree (release_id);


--
-- Name: artists_stage_name_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX artists_stage_name_index ON schema_.artists USING btree (stage_name);


--
-- Name: playlist_owners_user_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX playlist_owners_user_index ON schema_.playlist_owners USING btree (user_id);


--
-- Name: playlist_songs_playlist_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX playlist_songs_playlist_active_index ON schema_.playlist_songs USING btree (playlist_id) WHERE (date_removed IS NULL);


--
-- Name: release_likes_user_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX release_likes_user_active_index ON schema_.release_likes USING btree (user_id) WHERE (date_removed IS NULL);


--
-- Name: release_reviews_review_id_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX release_reviews_review_id_index ON schema_.release_reviews USING btree (review_id);


--
-- Name: releases_date_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX releases_date_index ON schema_.releases USING btree (release_date DESC);


--
-- Name: reviews_user_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX reviews_user_active_index ON schema_.reviews USING btree (user_id) WHERE (date_removed IS NULL);


--
-- Name: song_likes_song_user_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX song_likes_song_user_active_index ON schema_.song_likes USING btree (song_id, user_id) WHERE (date_removed IS NULL);


--
-- Name: song_reviews_review_id_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX song_reviews_review_id_index ON schema_.song_reviews USING btree (review_id);


--
-- Name: songs_releases_song_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX songs_releases_song_active_index ON schema_.songs_releases USING btree (song_id) WHERE (removed_date IS NULL);


--
-- Name: streams_user_timestamp_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX streams_user_timestamp_index ON schema_.streams USING btree (user_id, stream_timestamp DESC);


--
-- Name: user_follows_followed_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX user_follows_followed_active_index ON schema_.user_follows USING btree (followed_user_id) WHERE (date_until IS NULL);


--
-- Name: user_follows_user_active_index; Type: INDEX; Schema: schema_; Owner: -
--

CREATE INDEX user_follows_user_active_index ON schema_.user_follows USING btree (user_id) WHERE (date_until IS NULL);


--
-- Name: playlists rl_private_playlists_must_not_have_public_likes; Type: RULE; Schema: schema_; Owner: -
--

CREATE RULE rl_private_playlists_must_not_have_public_likes AS
    ON UPDATE TO schema_.playlists
   WHERE ((old.is_private = false) AND (new.is_private = true)) DO  UPDATE schema_.playlist_likes pl SET date_removed = now()
  WHERE ((pl.playlist_id = new.id) AND (NOT (pl.user_id IN ( SELECT po.user_id
           FROM schema_.playlist_owners po
          WHERE (po.playlist_id = new.id)))) AND (pl.date_removed IS NULL));


--
-- Name: import_requests trg_import_request_streams_must_not_decrease; Type: TRIGGER; Schema: schema_; Owner: -
--

CREATE TRIGGER trg_import_request_streams_must_not_decrease BEFORE UPDATE ON schema_.import_requests FOR EACH ROW EXECUTE FUNCTION schema_.check_import_request_streams_added();


--
-- Name: releases trg_release_must_have_artist; Type: TRIGGER; Schema: schema_; Owner: -
--

CREATE CONSTRAINT TRIGGER trg_release_must_have_artist AFTER INSERT ON schema_.releases DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION schema_.check_release_has_artist();


--
-- Name: releases trg_release_must_have_song; Type: TRIGGER; Schema: schema_; Owner: -
--

CREATE CONSTRAINT TRIGGER trg_release_must_have_song AFTER INSERT ON schema_.releases DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION schema_.check_release_has_song();


--
-- Name: songs_releases trg_release_must_have_song_after_delete; Type: TRIGGER; Schema: schema_; Owner: -
--

CREATE CONSTRAINT TRIGGER trg_release_must_have_song_after_delete AFTER DELETE ON schema_.songs_releases DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION schema_.check_release_has_song_after_delete();


--
-- Name: songs trg_song_must_have_artist; Type: TRIGGER; Schema: schema_; Owner: -
--

CREATE CONSTRAINT TRIGGER trg_song_must_have_artist AFTER INSERT OR UPDATE ON schema_.songs DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION schema_.check_song_has_artist();


--
-- Name: songs_artists trg_song_must_have_artist_after_delete; Type: TRIGGER; Schema: schema_; Owner: -
--

CREATE CONSTRAINT TRIGGER trg_song_must_have_artist_after_delete AFTER DELETE ON schema_.songs_artists DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION schema_.check_song_has_artist_after_delete();


--
-- Name: songs trg_song_must_have_release; Type: TRIGGER; Schema: schema_; Owner: -
--

CREATE CONSTRAINT TRIGGER trg_song_must_have_release AFTER INSERT OR UPDATE ON schema_.songs DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION schema_.check_song_has_release();


--
-- Name: users trg_user_must_have_streaming_account; Type: TRIGGER; Schema: schema_; Owner: -
--

CREATE CONSTRAINT TRIGGER trg_user_must_have_streaming_account AFTER INSERT ON schema_.users DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION schema_.check_user_has_streaming_account();


--
-- Name: artists_releases artists_releases_artist_roles_fk; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artists_releases
    ADD CONSTRAINT artists_releases_artist_roles_fk FOREIGN KEY (artist_role_id) REFERENCES schema_.artist_roles(id);


--
-- Name: artist_follows fk_artist_followers_artists; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artist_follows
    ADD CONSTRAINT fk_artist_followers_artists FOREIGN KEY (followed_artist_id) REFERENCES schema_.artists(id);


--
-- Name: artist_follows fk_artist_followers_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artist_follows
    ADD CONSTRAINT fk_artist_followers_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: artists_aliases fk_artists_aliases_artists; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artists_aliases
    ADD CONSTRAINT fk_artists_aliases_artists FOREIGN KEY (artist_id) REFERENCES schema_.artists(id);


--
-- Name: artists_releases fk_artists_releases_artists; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artists_releases
    ADD CONSTRAINT fk_artists_releases_artists FOREIGN KEY (artist_id) REFERENCES schema_.artists(id);


--
-- Name: artists_releases fk_artists_releases_releases; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.artists_releases
    ADD CONSTRAINT fk_artists_releases_releases FOREIGN KEY (release_id) REFERENCES schema_.releases(id);


--
-- Name: genres fk_genres_genres; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.genres
    ADD CONSTRAINT fk_genres_genres FOREIGN KEY (subgenre_of) REFERENCES schema_.genres(id);


--
-- Name: import_errors fk_import_errors_import_requests; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.import_errors
    ADD CONSTRAINT fk_import_errors_import_requests FOREIGN KEY (import_id) REFERENCES schema_.import_requests(id);


--
-- Name: import_requests fk_import_requests_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.import_requests
    ADD CONSTRAINT fk_import_requests_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: playlist_likes fk_playlist_likes_playlists; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_likes
    ADD CONSTRAINT fk_playlist_likes_playlists FOREIGN KEY (playlist_id) REFERENCES schema_.playlists(id);


--
-- Name: playlist_likes fk_playlist_likes_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_likes
    ADD CONSTRAINT fk_playlist_likes_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: playlist_songs fk_playlist_songs_playlists; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_songs
    ADD CONSTRAINT fk_playlist_songs_playlists FOREIGN KEY (playlist_id) REFERENCES schema_.playlists(id);


--
-- Name: playlist_songs fk_playlist_songs_songs; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_songs
    ADD CONSTRAINT fk_playlist_songs_songs FOREIGN KEY (song_id) REFERENCES schema_.songs(id);


--
-- Name: playlist_songs fk_playlist_songs_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_songs
    ADD CONSTRAINT fk_playlist_songs_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: playlist_owners fk_playlists_owners_playlists; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_owners
    ADD CONSTRAINT fk_playlists_owners_playlists FOREIGN KEY (playlist_id) REFERENCES schema_.playlists(id);


--
-- Name: playlist_owners fk_playlists_owners_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.playlist_owners
    ADD CONSTRAINT fk_playlists_owners_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: release_covers fk_release_covers_releases; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.release_covers
    ADD CONSTRAINT fk_release_covers_releases FOREIGN KEY (release_id) REFERENCES schema_.releases(id);


--
-- Name: release_likes fk_release_likes_releases; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.release_likes
    ADD CONSTRAINT fk_release_likes_releases FOREIGN KEY (release_id) REFERENCES schema_.releases(id);


--
-- Name: release_likes fk_release_likes_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.release_likes
    ADD CONSTRAINT fk_release_likes_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: release_reviews fk_release_reviews_releases; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.release_reviews
    ADD CONSTRAINT fk_release_reviews_releases FOREIGN KEY (release_id) REFERENCES schema_.releases(id);


--
-- Name: release_reviews fk_release_reviews_reviews; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.release_reviews
    ADD CONSTRAINT fk_release_reviews_reviews FOREIGN KEY (review_id) REFERENCES schema_.reviews(id);


--
-- Name: releases_genres fk_releases_genres_genres; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.releases_genres
    ADD CONSTRAINT fk_releases_genres_genres FOREIGN KEY (genre_id) REFERENCES schema_.genres(id);


--
-- Name: releases_genres fk_releases_genres_releases; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.releases_genres
    ADD CONSTRAINT fk_releases_genres_releases FOREIGN KEY (release_id) REFERENCES schema_.releases(id);



--
-- Name: releases fk_releases_release_covers; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.releases
    ADD CONSTRAINT fk_releases_release_covers FOREIGN KEY (main_cover_id) REFERENCES schema_.release_covers(id);


--
-- Name: song_likes fk_song_likes_songs; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.song_likes
    ADD CONSTRAINT fk_song_likes_songs FOREIGN KEY (song_id) REFERENCES schema_.songs(id);


--
-- Name: song_likes fk_song_likes_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.song_likes
    ADD CONSTRAINT fk_song_likes_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: song_reviews fk_song_reviews_reviews; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.song_reviews
    ADD CONSTRAINT fk_song_reviews_reviews FOREIGN KEY (review_id) REFERENCES schema_.reviews(id);


--
-- Name: song_reviews fk_song_reviews_songs; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.song_reviews
    ADD CONSTRAINT fk_song_reviews_songs FOREIGN KEY (song_id) REFERENCES schema_.songs(id);


--
-- Name: reviews fk_song_reviews_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.reviews
    ADD CONSTRAINT fk_song_reviews_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: songs_artists fk_songs_artists_artists; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_artists
    ADD CONSTRAINT fk_songs_artists_artists FOREIGN KEY (artist_id) REFERENCES schema_.artists(id);


--
-- Name: songs_artists fk_songs_artists_songs; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_artists
    ADD CONSTRAINT fk_songs_artists_songs FOREIGN KEY (song_id) REFERENCES schema_.songs(id);


--
-- Name: songs_genres fk_songs_genres_genres; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_genres
    ADD CONSTRAINT fk_songs_genres_genres FOREIGN KEY (genre_id) REFERENCES schema_.genres(id);


--
-- Name: songs_genres fk_songs_genres_songs; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_genres
    ADD CONSTRAINT fk_songs_genres_songs FOREIGN KEY (song_id) REFERENCES schema_.songs(id);


--
-- Name: songs_releases fk_songs_releases_releases; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_releases
    ADD CONSTRAINT fk_songs_releases_releases FOREIGN KEY (release_id) REFERENCES schema_.releases(id);


--
-- Name: songs_releases fk_songs_releases_songs; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.songs_releases
    ADD CONSTRAINT fk_songs_releases_songs FOREIGN KEY (song_id) REFERENCES schema_.songs(id);


--
-- Name: streaming_accounts fk_streaming_accounts_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.streaming_accounts
    ADD CONSTRAINT fk_streaming_accounts_users FOREIGN KEY (user_id) REFERENCES schema_.users(id) ON DELETE CASCADE;


--
-- Name: streams fk_streams_songs; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.streams
    ADD CONSTRAINT fk_streams_songs FOREIGN KEY (song_id) REFERENCES schema_.songs(id);


--
-- Name: streams fk_streams_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.streams
    ADD CONSTRAINT fk_streams_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: user_follows fk_user_follows_users; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.user_follows
    ADD CONSTRAINT fk_user_follows_users FOREIGN KEY (user_id) REFERENCES schema_.users(id);


--
-- Name: user_follows fk_user_follows_users_0; Type: FK CONSTRAINT; Schema: schema_; Owner: -
--

ALTER TABLE ONLY schema_.user_follows
    ADD CONSTRAINT fk_user_follows_users_0 FOREIGN KEY (followed_user_id) REFERENCES schema_.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict Tvz776JbDlg8iDbja9S9QwUvKyezcDiVY7AkI2vccdObbI6fRNF41noRfkyPzDh

