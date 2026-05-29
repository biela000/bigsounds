CREATE SCHEMA IF NOT EXISTS schema_;

DROP TABLE IF EXISTS schema_.songs_releases CASCADE;
DROP TABLE IF EXISTS schema_.releases_labels CASCADE;
DROP TABLE IF EXISTS schema_.releases_genres CASCADE;
DROP TABLE IF EXISTS schema_.release_reviews CASCADE;
DROP TABLE IF EXISTS schema_.release_likes CASCADE;
DROP TABLE IF EXISTS schema_.release_covers CASCADE;
DROP TABLE IF EXISTS schema_.artists_releases CASCADE;
DROP TABLE IF EXISTS schema_.import_errors CASCADE;
DROP TABLE IF EXISTS schema_.user_follows CASCADE;
DROP TABLE IF EXISTS schema_.streams CASCADE;
DROP TABLE IF EXISTS schema_.streaming_accounts CASCADE;
DROP TABLE IF EXISTS schema_.song_reviews CASCADE;
DROP TABLE IF EXISTS schema_.song_likes CASCADE;
DROP TABLE IF EXISTS schema_.playlist_owners CASCADE;
DROP TABLE IF EXISTS schema_.playlist_songs CASCADE;
DROP TABLE IF EXISTS schema_.playlist_likes CASCADE;
DROP TABLE IF EXISTS schema_.import_requests CASCADE;
DROP TABLE IF EXISTS schema_.artist_follows CASCADE;
DROP TABLE IF EXISTS schema_.songs_genres CASCADE;
DROP TABLE IF EXISTS schema_.songs_artists CASCADE;
DROP TABLE IF EXISTS schema_.artists_aliases CASCADE;
DROP TABLE IF EXISTS schema_.releases CASCADE;
DROP TABLE IF EXISTS schema_.reviews CASCADE;
DROP TABLE IF EXISTS schema_.users CASCADE;
DROP TABLE IF EXISTS schema_.songs CASCADE;
DROP TABLE IF EXISTS schema_.playlists CASCADE;
DROP TABLE IF EXISTS schema_.labels CASCADE;
DROP TABLE IF EXISTS schema_.genres CASCADE;
DROP TABLE IF EXISTS schema_.artists CASCADE;

DROP TYPE IF EXISTS artist_role_enum CASCADE;
DROP TYPE IF EXISTS release_format_enum CASCADE;
DROP TYPE IF EXISTS import_status_enum CASCADE;

CREATE TYPE artist_role_enum AS ENUM (
    'primary artist', 'featured artist', 'remixer', 'songwriter', 
    'composer', 'producer', 'mixer', 'recording engineer', 
    'mastering engineer', 'vocal producer'
);

CREATE TYPE release_format_enum AS ENUM (
    'LP', 'EP', 'Mixtape', 'Compilation', 'Single'
);

CREATE TYPE import_status_enum AS ENUM (
    'completed', 'processing', 'pending', 'failed'
);

CREATE  TABLE schema_.artists ( 
	id                   integer  NOT NULL  ,
	stage_name           text  NOT NULL  ,
	birth_date           date    ,
	website              text    ,
	profile_picture      text    ,
	description          text    ,
	CONSTRAINT pk_tbl_2 PRIMARY KEY ( id )
 );

CREATE  TABLE schema_.artists_aliases ( 
	artist_id            integer  NOT NULL  ,
	artist_alias         text  NOT NULL  ,
	CONSTRAINT pk_artists_aliases PRIMARY KEY ( artist_id, artist_alias ),
	CONSTRAINT fk_artists_aliases_artists FOREIGN KEY ( artist_id ) REFERENCES schema_.artists( id )   
 );

CREATE  TABLE schema_.genres ( 
	id                   integer  NOT NULL  ,
	name                 text  NOT NULL  ,
	subgenre_of          integer    ,
	CONSTRAINT pk_tbl_0 PRIMARY KEY ( id ),
	CONSTRAINT fk_genres_genres FOREIGN KEY ( subgenre_of ) REFERENCES schema_.genres( id )   
 );

CREATE  TABLE schema_.labels ( 
	id                   integer  NOT NULL  ,
	name                 text  NOT NULL  ,
	CONSTRAINT pk_tbl_3 PRIMARY KEY ( id )
 );

CREATE  TABLE schema_.playlists ( 
	id                   integer  NOT NULL  ,
	date_added           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_removed         timestamp    ,
	cover                text DEFAULT 'untitled.png' NOT NULL  ,
	is_private           boolean DEFAULT false NOT NULL  ,
	name                 text    ,
	CONSTRAINT pk_playlists PRIMARY KEY ( id )
 );

ALTER TABLE schema_.playlists ADD CONSTRAINT cns_playlists CHECK ( date_removed IS NULL OR date_added<date_removed );

CREATE  TABLE schema_.songs ( 
	id                   integer  NOT NULL  ,
	title                varchar(100)  NOT NULL  ,
	duration_ms          integer  NOT NULL  ,
	CONSTRAINT pk_tbl PRIMARY KEY ( id )
 );

ALTER TABLE schema_.songs ADD CONSTRAINT cns_songs CHECK ( duration_ms > 0 );

CREATE  TABLE schema_.songs_artists ( 
	song_id              integer  NOT NULL  ,
	artist_id            integer  NOT NULL  ,
	artist_role          artist_role_enum  NOT NULL  ,
	CONSTRAINT pk_songs_artists PRIMARY KEY ( song_id, artist_id, artist_role ),
	CONSTRAINT fk_songs_artists_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   ,
	CONSTRAINT fk_songs_artists_artists FOREIGN KEY ( artist_id ) REFERENCES schema_.artists( id )   
 );

CREATE  TABLE schema_.songs_genres ( 
	song_id              integer  NOT NULL  ,
	genre_id             integer  NOT NULL  ,
	CONSTRAINT pk_songs_genres PRIMARY KEY ( song_id, genre_id ),
	CONSTRAINT fk_songs_genres_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   ,
	CONSTRAINT fk_songs_genres_genres FOREIGN KEY ( genre_id ) REFERENCES schema_.genres( id )   
 );

CREATE  TABLE schema_.users ( 
	id                   integer  NOT NULL  ,
	name                 text  NOT NULL  ,
	passwd               text  NOT NULL  ,
	date_joined          timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_left            timestamp    ,
	CONSTRAINT pk_users PRIMARY KEY ( id )
 );

ALTER TABLE schema_.users ADD CONSTRAINT cns_users CHECK ( date_left IS NULL OR date_joined<date_left );

CREATE  TABLE schema_.artist_follows ( 
	user_id              integer  NOT NULL  ,
	followed_artist_id   integer  NOT NULL  ,
	date_from            timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_until           timestamp    ,
	CONSTRAINT pk_artist_follows PRIMARY KEY ( user_id, followed_artist_id, date_from ),
	CONSTRAINT fk_artist_followers_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_artist_followers_artists FOREIGN KEY ( followed_artist_id ) REFERENCES schema_.artists( id )   
 );

ALTER TABLE schema_.artist_follows ADD CONSTRAINT cns_artist_follows CHECK ( date_until IS NULL OR date_from<date_until );

CREATE  TABLE schema_.import_requests ( 
	id                   integer  NOT NULL  ,
	status               import_status_enum  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	file_name            text  NOT NULL  ,
	file_hash            text  NOT NULL  ,
	total_streams_found  integer DEFAULT 0 NOT NULL  ,
	streams_successfully_added integer DEFAULT 0 NOT NULL  ,
	upload_date          timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	completed_date       timestamp    ,
	CONSTRAINT pk_import_requests PRIMARY KEY ( id ),
	CONSTRAINT fk_import_requests_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   
 );

ALTER TABLE schema_.import_requests ADD CONSTRAINT cns_import_requests CHECK ( completed_date IS NULL OR completed_date<=upload_date );

ALTER TABLE schema_.import_requests ADD CONSTRAINT cns_import_requests_0 CHECK ( streams_successfully_added<=total_streams_found );

CREATE  TABLE schema_.playlist_likes ( 
	playlist_id          integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	date_added           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_removed         timestamp    ,
	CONSTRAINT pk_playlist_likes PRIMARY KEY ( playlist_id, user_id, date_added ),
	CONSTRAINT fk_playlist_likes_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_playlist_likes_playlists FOREIGN KEY ( playlist_id ) REFERENCES schema_.playlists( id )   
 );

ALTER TABLE schema_.playlist_likes ADD CONSTRAINT cns_playlist_likes CHECK ( date_removed IS NULL OR date_added<date_removed );

CREATE  TABLE schema_.playlist_owners ( 
	playlist_id          integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	CONSTRAINT pk_playlists_owners PRIMARY KEY ( playlist_id, user_id ),
	CONSTRAINT fk_playlists_owners_playlists FOREIGN KEY ( playlist_id ) REFERENCES schema_.playlists( id )   ,
	CONSTRAINT fk_playlists_owners_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   
 );

CREATE  TABLE schema_.playlist_songs ( 
	playlist_id          integer  NOT NULL  ,
	song_id              integer  NOT NULL  ,
	date_added           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_removed         timestamp    ,
	user_id              integer  NOT NULL  ,
	CONSTRAINT pk_playlist_songs PRIMARY KEY ( playlist_id, song_id, date_added ),
	CONSTRAINT fk_playlist_songs_playlists FOREIGN KEY ( playlist_id ) REFERENCES schema_.playlists( id )   ,
	CONSTRAINT fk_playlist_songs_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   ,
	CONSTRAINT fk_playlist_songs_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   
 );

ALTER TABLE schema_.playlist_songs ADD CONSTRAINT cns_playlist_songs CHECK ( date_removed IS NULL OR date_added<date_removed );

CREATE  TABLE schema_.reviews ( 
	id                   integer  NOT NULL  ,
	score                integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	date_added           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_removed         timestamp    ,
	CONSTRAINT pk_song_reviews PRIMARY KEY ( id ),
	CONSTRAINT fk_song_reviews_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   
 );

ALTER TABLE schema_.reviews ADD CONSTRAINT cns_reviews CHECK ( date_removed IS NULL OR date_added<date_removed );

CREATE  TABLE schema_.song_likes ( 
	user_id              integer  NOT NULL  ,
	song_id              integer  NOT NULL  ,
	date_added           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_removed         timestamp    ,
	CONSTRAINT pk_song_likes PRIMARY KEY ( user_id, song_id, date_added ),
	CONSTRAINT fk_song_likes_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_song_likes_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   
 );

ALTER TABLE schema_.song_likes ADD CONSTRAINT cns_song_likes CHECK ( date_removed IS NULL OR date_added<date_removed );

CREATE  TABLE schema_.song_reviews ( 
	song_id              integer  NOT NULL  ,
	review_id            integer  NOT NULL  ,
	CONSTRAINT pk_song_reviews_0 PRIMARY KEY ( song_id, review_id ),
	CONSTRAINT fk_song_reviews_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   ,
	CONSTRAINT fk_song_reviews_reviews FOREIGN KEY ( review_id ) REFERENCES schema_.reviews( id )   
 );

CREATE  TABLE schema_.streaming_accounts ( 
	user_id              integer  NOT NULL  ,
	streaming_id         text  NOT NULL  ,
	access_token         text  NOT NULL  ,
	refresh_token        text  NOT NULL  ,
	token_expires_at     timestamp  NOT NULL  ,
	CONSTRAINT pk_streaming_accounts PRIMARY KEY ( user_id ),
	CONSTRAINT unq_streaming_accounts UNIQUE ( streaming_id ) ,
	CONSTRAINT fk_streaming_accounts_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   
 );

CREATE  TABLE schema_.streams ( 
	id                   integer  NOT NULL  ,
	song_id              integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	stream_timestamp     timestamp  NOT NULL  ,
	CONSTRAINT pk_streams PRIMARY KEY ( id ),
	CONSTRAINT fk_streams_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_streams_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   
 );

CREATE  TABLE schema_.user_follows ( 
	user_id              integer  NOT NULL  ,
	followed_user_id     integer  NOT NULL  ,
	date_from            timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_until           timestamp    ,
	CONSTRAINT pk_user_follows PRIMARY KEY ( user_id, followed_user_id, date_from ),
	CONSTRAINT fk_user_follows_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_user_follows_users_0 FOREIGN KEY ( followed_user_id ) REFERENCES schema_.users( id )   
 );

ALTER TABLE schema_.user_follows ADD CONSTRAINT cns_user_follows CHECK ( date_until IS NULL OR date_from<date_until );

CREATE  TABLE schema_.import_errors ( 
	id                   integer  NOT NULL  ,
	import_id            integer  NOT NULL  ,
	error_message        text  NOT NULL  ,
	raw_json_record      jsonb  NOT NULL  ,
	CONSTRAINT pk_import_errors PRIMARY KEY ( id ),
	CONSTRAINT fk_import_errors_import_requests FOREIGN KEY ( import_id ) REFERENCES schema_.import_requests( id )   
 );

CREATE  TABLE schema_.artists_releases ( 
	artist_id            integer  NOT NULL  ,
	release_id           integer  NOT NULL  ,
	artist_role          artist_role_enum  NOT NULL  ,
	CONSTRAINT pk_artists_releases PRIMARY KEY ( artist_id, release_id, artist_role )
 );

CREATE  TABLE schema_.release_covers ( 
	id                   integer  NOT NULL  ,
	cover                text  NOT NULL  ,
	release_id           integer  NOT NULL  ,
	used_since           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	used_until           timestamp    ,
	CONSTRAINT pk_release_covers PRIMARY KEY ( id )
 );

ALTER TABLE schema_.release_covers ADD CONSTRAINT cns_release_covers CHECK ( used_until IS NULL OR used_since<used_until );

CREATE  TABLE schema_.release_likes ( 
	release_id           integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	date_added           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	date_removed         timestamp    ,
	CONSTRAINT pk_release_likes PRIMARY KEY ( release_id, user_id, date_added )
 );

ALTER TABLE schema_.release_likes ADD CONSTRAINT cns_release_likes CHECK ( date_removed IS NULL OR date_added<date_removed );

CREATE  TABLE schema_.release_reviews ( 
	release_id           integer  NOT NULL  ,
	review_id            integer  NOT NULL  ,
	CONSTRAINT pk_release_reviews PRIMARY KEY ( release_id, review_id )
 );

CREATE  TABLE schema_.releases ( 
	id                   integer  NOT NULL  ,
	title                varchar(100)  NOT NULL  ,
	release_date         date  NOT NULL  ,
	format               release_format_enum  NOT NULL  ,
	main_cover_id        integer    ,
	CONSTRAINT pk_tbl_1 PRIMARY KEY ( id )
 );

CREATE  TABLE schema_.releases_genres ( 
	genre_id             integer  NOT NULL  ,
	release_id           integer  NOT NULL  ,
	CONSTRAINT pk_releases_genres PRIMARY KEY ( genre_id, release_id )
 );

CREATE  TABLE schema_.releases_labels ( 
	label_id             integer  NOT NULL  ,
	release_id           integer  NOT NULL  ,
	CONSTRAINT pk_releases_labels PRIMARY KEY ( label_id, release_id )
 );

CREATE  TABLE schema_.songs_releases ( 
	song_id              integer  NOT NULL  ,
	release_id           integer  NOT NULL  ,
	added_date           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL  ,
	removed_date         timestamp    ,
	CONSTRAINT pk_songs_releases PRIMARY KEY ( song_id, release_id, added_date )
 );

ALTER TABLE schema_.songs_releases ADD CONSTRAINT cns_songs_releases CHECK ( removed_date IS NULL OR added_date<removed_date );

ALTER TABLE schema_.artists_releases ADD CONSTRAINT fk_artists_releases_releases FOREIGN KEY ( release_id ) REFERENCES schema_.releases( id );

ALTER TABLE schema_.artists_releases ADD CONSTRAINT fk_artists_releases_artists FOREIGN KEY ( artist_id ) REFERENCES schema_.artists( id );

ALTER TABLE schema_.release_covers ADD CONSTRAINT fk_release_covers_releases FOREIGN KEY ( release_id ) REFERENCES schema_.releases( id );

ALTER TABLE schema_.release_likes ADD CONSTRAINT fk_release_likes_releases FOREIGN KEY ( release_id ) REFERENCES schema_.releases( id );

ALTER TABLE schema_.release_likes ADD CONSTRAINT fk_release_likes_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id );

ALTER TABLE schema_.release_reviews ADD CONSTRAINT fk_release_reviews_releases FOREIGN KEY ( release_id ) REFERENCES schema_.releases( id );

ALTER TABLE schema_.release_reviews ADD CONSTRAINT fk_release_reviews_reviews FOREIGN KEY ( review_id ) REFERENCES schema_.reviews( id );

ALTER TABLE schema_.releases ADD CONSTRAINT fk_releases_release_covers FOREIGN KEY ( main_cover_id ) REFERENCES schema_.release_covers( id );

ALTER TABLE schema_.releases_genres ADD CONSTRAINT fk_releases_genres_genres FOREIGN KEY ( genre_id ) REFERENCES schema_.genres( id );

ALTER TABLE schema_.releases_genres ADD CONSTRAINT fk_releases_genres_releases FOREIGN KEY ( release_id ) REFERENCES schema_.releases( id );

ALTER TABLE schema_.releases_labels ADD CONSTRAINT fk_releases_labels_labels FOREIGN KEY ( label_id ) REFERENCES schema_.labels( id );

ALTER TABLE schema_.releases_labels ADD CONSTRAINT fk_releases_labels_releases FOREIGN KEY ( release_id ) REFERENCES schema_.releases( id );

ALTER TABLE schema_.songs_releases ADD CONSTRAINT fk_songs_releases_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id );

ALTER TABLE schema_.songs_releases ADD CONSTRAINT fk_songs_releases_releases FOREIGN KEY ( release_id ) REFERENCES schema_.releases( id );

INSERT INTO schema_.artists (id, stage_name, birth_date, website, description) VALUES 
(1, 'The Beatles', '1960-01-01', 'https://thebeatles.com', 'Legendarny zespół rockowy z Liverpoolu.'),
(2, 'Daft Punk', '1993-01-01', 'https://daftpunk.com', 'Francuski duet muzyki elektronicznej.');

INSERT INTO schema_.genres (id, name, subgenre_of) VALUES 
(1, 'Rock', NULL),
(2, 'Electronic', NULL),
(3, 'Pop Rock', 1); 

INSERT INTO schema_.labels (id, name) VALUES 
(1, 'EMI'),
(2, 'Virgin Records');

INSERT INTO schema_.users (id, name, passwd) VALUES 
(1, 'meloman_99', 'zaszyfrowane_haslo_1'),
(2, 'techno_king', 'zaszyfrowane_haslo_2');

INSERT INTO schema_.songs (id, title, duration_ms) VALUES 
(1, 'Let It Be', 243000),
(2, 'Get Lucky', 368000);

INSERT INTO schema_.playlists (id, is_private, name) VALUES 
(1, true, 'Moje Ulubione'),
(2, false, 'Do Biegania');

INSERT INTO schema_.releases (id, title, release_date, format, main_cover_id) VALUES 
(1, 'Let It Be (Album)', '1970-05-08', 'LP', NULL),
(2, 'Random Access Memories', '2013-05-17', 'LP', NULL);

INSERT INTO schema_.release_covers (id, cover, release_id) VALUES 
(101, 'let_it_be_cover.jpg', 1),
(102, 'daft_punk_ram.png', 2);

UPDATE schema_.releases SET main_cover_id = 101 WHERE id = 1;
UPDATE schema_.releases SET main_cover_id = 102 WHERE id = 2;

INSERT INTO schema_.artists_aliases (artist_id, artist_alias) VALUES 
(1, 'The Fab Four'),
(2, 'Guy-Manuel & Thomas');

INSERT INTO schema_.songs_artists (song_id, artist_id, artist_role) VALUES 
(1, 1, 'primary artist'),
(2, 2, 'primary artist');

INSERT INTO schema_.songs_genres (song_id, genre_id) VALUES 
(1, 3),
(2, 2); 

INSERT INTO schema_.songs_releases (song_id, release_id) VALUES 
(1, 1),
(2, 2);

INSERT INTO schema_.artists_releases (artist_id, release_id, artist_role) VALUES 
(1, 1, 'primary artist'),
(2, 2, 'primary artist');

INSERT INTO schema_.releases_genres (genre_id, release_id) VALUES (3, 1), (2, 2);
INSERT INTO schema_.releases_labels (label_id, release_id) VALUES (1, 1), (2, 2);

INSERT INTO schema_.artist_follows (user_id, followed_artist_id) VALUES (1, 1);
INSERT INTO schema_.user_follows (user_id, followed_user_id) VALUES (2, 1);

INSERT INTO schema_.song_likes (user_id, song_id) VALUES (1, 1), (2, 2);
INSERT INTO schema_.release_likes (release_id, user_id) VALUES (1, 1);

INSERT INTO schema_.reviews (id, score, user_id) VALUES 
(1, 10, 1), 
(2, 9, 2);  

INSERT INTO schema_.song_reviews (song_id, review_id) VALUES (1, 1);
INSERT INTO schema_.release_reviews (release_id, review_id) VALUES (2, 2);

INSERT INTO schema_.playlist_owners (playlist_id, user_id) VALUES (1, 1), (2, 2);
INSERT INTO schema_.playlist_songs (playlist_id, song_id, user_id) VALUES (1, 1, 1);
INSERT INTO schema_.playlist_likes (playlist_id, user_id) VALUES (1, 2);

INSERT INTO schema_.streaming_accounts (user_id, streaming_id, access_token, refresh_token, token_expires_at) VALUES 
(1, 'spotify_user_id_123', 'access_abc', 'refresh_xyz', '2026-12-31 23:59:59');

INSERT INTO schema_.streams (id, song_id, user_id, stream_timestamp) VALUES 
(1, 1, 1, CURRENT_TIMESTAMP);

INSERT INTO schema_.import_requests (id, status, user_id, file_name, file_hash) VALUES 
(1, 'completed', 1, 'history_export.json', 'sha256_hash_123');

INSERT INTO schema_.import_errors (id, import_id, error_message, raw_json_record) VALUES 
(1, 1, 'Brak metadanych utworu', '{"artist": "Unknown", "msPlayed": 0}'::jsonb);
