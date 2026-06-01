CREATE OR REPLACE RULE songs_on_delete
AS ON DELETE TO schema_.songs
DO INSTEAD NOTHING;

CREATE OR REPLACE RULE artists_on_delete
AS ON DELETE TO schema_.artists
DO INSTEAD NOTHING;

CREATE OR REPLACE RULE releases_on_delete
AS ON DELETE TO schema_.releases
DO INSTEAD NOTHING;

CREATE OR REPLACE RULE streaming_accounts_on_delete
AS ON DELETE TO schema_.streaming_accounts
DO INSTEAD NOTHING;


CREATE OR REPLACE RULE soft_delete_playlists AS
    ON DELETE TO schema_.playlists
    DO INSTEAD
        UPDATE schema_.playlists
        SET date_removed = now()
        WHERE id = OLD.id
          AND date_removed IS NULL;

CREATE OR REPLACE RULE soft_delete_reviews AS
    ON DELETE TO schema_.reviews
    DO INSTEAD
        UPDATE schema_.reviews
        SET date_removed = now()
        WHERE id = OLD.id
          AND date_removed IS NULL;

CREATE OR REPLACE RULE soft_delete_playlist_likes AS
    ON DELETE TO schema_.playlist_likes
    DO INSTEAD
        UPDATE schema_.playlist_likes
        SET date_removed = now()
        WHERE playlist_id = OLD.playlist_id 
          AND user_id = OLD.user_id 
          AND date_added = OLD.date_added
          AND date_removed IS NULL;

CREATE OR REPLACE RULE soft_delete_playlist_songs AS
    ON DELETE TO schema_.playlist_songs
    DO INSTEAD
        UPDATE schema_.playlist_songs
        SET date_removed = now()
        WHERE playlist_id = OLD.playlist_id 
          AND song_id = OLD.song_id 
          AND date_added = OLD.date_added
          AND date_removed IS NULL;

CREATE OR REPLACE RULE soft_delete_release_likes AS
    ON DELETE TO schema_.release_likes
    DO INSTEAD
        UPDATE schema_.release_likes
        SET date_removed = now()
        WHERE release_id = OLD.release_id 
          AND user_id = OLD.user_id 
          AND date_added = OLD.date_added
          AND date_removed IS NULL;

CREATE OR REPLACE RULE soft_delete_song_likes AS
    ON DELETE TO schema_.song_likes
    DO INSTEAD
        UPDATE schema_.song_likes
        SET date_removed = now()
        WHERE user_id = OLD.user_id 
          AND song_id = OLD.song_id 
          AND date_added = OLD.date_added
          AND date_removed IS NULL;



CREATE OR REPLACE RULE soft_delete_songs_releases AS
    ON DELETE TO schema_.songs_releases
    DO INSTEAD
        UPDATE schema_.songs_releases
        SET removed_date = now()
        WHERE song_id = OLD.song_id 
          AND release_id = OLD.release_id 
          AND added_date = OLD.added_date
          AND removed_date IS NULL;



CREATE OR REPLACE RULE soft_delete_artist_follows AS
    ON DELETE TO schema_.artist_follows
    DO INSTEAD
        UPDATE schema_.artist_follows
        SET date_until = now()
        WHERE user_id = OLD.user_id 
          AND followed_artist_id = OLD.followed_artist_id 
          AND date_from = OLD.date_from
          AND date_until IS NULL;


CREATE OR REPLACE RULE soft_delete_user_follows AS
    ON DELETE TO schema_.user_follows
    DO INSTEAD
        UPDATE schema_.user_follows
        SET date_until = now()
        WHERE user_id = OLD.user_id 
          AND followed_user_id = OLD.followed_user_id 
          AND date_from = OLD.date_from
          AND date_until IS NULL;