CREATE SCHEMA IF NOT EXISTS schema_;

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
	date_added           date  NOT NULL  ,
	date_removed         date    ,
	cover                text    ,
	CONSTRAINT pk_playlists PRIMARY KEY ( id )
 );

CREATE  TABLE schema_.songs ( 
	id                   integer  NOT NULL  ,
	title                varchar(100)  NOT NULL  ,
	duration             interval  NOT NULL  ,
	CONSTRAINT pk_tbl PRIMARY KEY ( id )
 );

CREATE  TABLE schema_.songs_artists ( 
	song_id              integer  NOT NULL  ,
	artist_id            integer  NOT NULL  ,
	CONSTRAINT fk_songs_artists_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   ,
	CONSTRAINT fk_songs_artists_artists FOREIGN KEY ( artist_id ) REFERENCES schema_.artists( id )   
 );

CREATE  TABLE schema_.songs_genres ( 
	song_id              integer  NOT NULL  ,
	genre_id             integer  NOT NULL  ,
	CONSTRAINT fk_songs_genres_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   ,
	CONSTRAINT fk_songs_genres_genres FOREIGN KEY ( genre_id ) REFERENCES schema_.genres( id )   
 );

CREATE  TABLE schema_.users ( 
	id                   integer  NOT NULL  ,
	name                 text  NOT NULL  ,
	passwd               text  NOT NULL  ,
	date_joined          date  NOT NULL  ,
	date_left            date    ,
	CONSTRAINT pk_users PRIMARY KEY ( id )
 );

CREATE  TABLE schema_.artist_follows ( 
	user_id              integer  NOT NULL  ,
	followed_artist_id   integer  NOT NULL  ,
	date_from            date  NOT NULL  ,
	date_until           date    ,
	CONSTRAINT fk_artist_followers_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_artist_followers_artists FOREIGN KEY ( followed_artist_id ) REFERENCES schema_.artists( id )   
 );

CREATE  TABLE schema_.playlist_likes ( 
	playlist_id          integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	date_added           date  NOT NULL  ,
	date_removed         date    ,
	CONSTRAINT fk_playlist_likes_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_playlist_likes_playlists FOREIGN KEY ( playlist_id ) REFERENCES schema_.playlists( id )   
 );

CREATE  TABLE schema_.playlist_songs ( 
	playlist_id          integer  NOT NULL  ,
	song_id              integer  NOT NULL  ,
	date_added           date  NOT NULL  ,
	date_removed         date    ,
	user_id              integer  NOT NULL  ,
	name                 text  NOT NULL  ,
	CONSTRAINT fk_playlist_songs_playlists FOREIGN KEY ( playlist_id ) REFERENCES schema_.playlists( id )   ,
	CONSTRAINT fk_playlist_songs_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   ,
	CONSTRAINT fk_playlist_songs_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   
 );

CREATE  TABLE schema_.playlists_owners ( 
	playlist_id          integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	CONSTRAINT fk_playlists_owners_playlists FOREIGN KEY ( playlist_id ) REFERENCES schema_.playlists( id )   ,
	CONSTRAINT fk_playlists_owners_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   
 );

CREATE  TABLE schema_.reviews ( 
	id                   integer  NOT NULL  ,
	score                integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	date_added           date  NOT NULL  ,
	date_removed         date    ,
	CONSTRAINT pk_song_reviews PRIMARY KEY ( id ),
	CONSTRAINT fk_song_reviews_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   
 );

CREATE  TABLE schema_.song_likes ( 
	user_id              integer  NOT NULL  ,
	song_id              integer  NOT NULL  ,
	date_added           date  NOT NULL  ,
	date_removed         date    ,
	CONSTRAINT fk_song_likes_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_song_likes_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   
 );

CREATE  TABLE schema_.song_reviews ( 
	song_id              integer  NOT NULL  ,
	review_id            integer  NOT NULL  ,
	CONSTRAINT fk_song_reviews_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   ,
	CONSTRAINT fk_song_reviews_reviews FOREIGN KEY ( review_id ) REFERENCES schema_.reviews( id )   
 );

CREATE  TABLE schema_.streams ( 
	id                   integer  NOT NULL  ,
	song_id              integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	stream_datetime      date  NOT NULL  ,
	CONSTRAINT pk_streams PRIMARY KEY ( id ),
	CONSTRAINT fk_streams_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_streams_songs FOREIGN KEY ( song_id ) REFERENCES schema_.songs( id )   
 );

CREATE  TABLE schema_.user_follows ( 
	user_id              integer  NOT NULL  ,
	followed_user_id     integer  NOT NULL  ,
	date_from            date  NOT NULL  ,
	date_unitl           date    ,
	CONSTRAINT fk_user_follows_users FOREIGN KEY ( user_id ) REFERENCES schema_.users( id )   ,
	CONSTRAINT fk_user_follows_users_0 FOREIGN KEY ( followed_user_id ) REFERENCES schema_.users( id )   
 );

CREATE  TABLE schema_.artists_releases ( 
	artist_id            integer  NOT NULL  ,
	release_id           integer  NOT NULL  ,
	artist_role          artist_role_enum  NOT NULL  
 );

CREATE  TABLE schema_.release_covers ( 
	id                   integer  NOT NULL  ,
	cover                text  NOT NULL  ,
	release_id           integer  NOT NULL  ,
	used_since           date    ,
	used_until           date    ,
	CONSTRAINT pk_release_covers PRIMARY KEY ( id )
 );

CREATE  TABLE schema_.release_likes ( 
	release_id           integer  NOT NULL  ,
	user_id              integer  NOT NULL  ,
	date_added           date  NOT NULL  ,
	date_removed         date    
 );

CREATE  TABLE schema_.release_reviews ( 
	release_id           integer  NOT NULL  ,
	review_id            integer  NOT NULL  
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
	release_id           integer  NOT NULL  
 );

CREATE  TABLE schema_.releases_labels ( 
	label_id             integer  NOT NULL  ,
	release_id           integer  NOT NULL  
 );

CREATE  TABLE schema_.songs_releases ( 
	song_id              integer  NOT NULL  ,
	release_id           integer  NOT NULL  ,
	added_date           date    ,
	removed_date         date    ,
	CONSTRAINT unq_songs_releases_release_id UNIQUE ( release_id ) 
 );

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

