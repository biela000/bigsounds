--foreign key indexes
CREATE INDEX streams_user_id_index ON
schema_.streams (user_id);

CREATE INDEX streams_song_id_index ON 
schema_.streams (song_id);

CREATE INDEX playlist_songs_song_id_index ON 
schema_.playlist_songs (song_id);

CREATE INDEX song_artists_artist_id_index ON 
schema_.songs_artists (artist_id);

CREATE INDEX artists_releases_release_id_index ON 
schema_.artists_releases (release_id);

--search indexes

CREATE INDEX artists_stage_name_index ON
schema_.artists (stage_name);

CREATE INDEX songs_title_index ON 
schema_.songs (title);

CREATE INDEX releases_title_index ON 
schema_.releases (title);

--time indexes

CREATE INDEX streams_stream_timestamp_index ON 
schema_.streams (stream_timestamp);