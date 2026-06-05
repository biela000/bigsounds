BEGIN;
--these indexes ensure that you can't insert two rows for the same user and song
--where date_removed is null

CREATE UNIQUE INDEX unq_active_song_like 
    ON schema_.song_likes (user_id, song_id) WHERE date_removed IS NULL;

CREATE UNIQUE INDEX unq_active_release_like 
    ON schema_.release_likes (user_id, release_id) WHERE date_removed IS NULL;

CREATE UNIQUE INDEX unq_active_user_follow 
    ON schema_.user_follows (user_id, followed_user_id) WHERE date_until IS NULL;

CREATE UNIQUE INDEX unq_active_artist_follow 
    ON schema_.artist_follows (user_id, followed_artist_id) WHERE date_until IS NULL;

CREATE UNIQUE INDEX unq_active_playlist_like 
    ON schema_.playlist_likes (playlist_id, user_id) WHERE date_removed IS NULL;


--artist cannot have two active rows for the same band
CREATE UNIQUE INDEX unq_active_band_membership 
    ON schema_.artists_bands (artist_id, band_id) WHERE date_left IS NULL;

--changed the trigger to implement soft deletes
CREATE OR REPLACE FUNCTION schema_.check_release_has_song_after_delete() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM schema_.songs_releases 
        WHERE release_id = OLD.release_id AND date_removed IS NULL
    ) THEN
        RAISE EXCEPTION 'A release cannot be left with zero active songs.';
    END IF;
    RETURN OLD;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION schema_.check_song_has_artist_after_delete() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM schema_.songs_artists WHERE song_id = OLD.song_id
    ) THEN
        RAISE EXCEPTION 'A song cannot be left with zero artists.';
    END IF;
    RETURN OLD;
END
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_song_must_have_artist_after_delete 
AFTER DELETE ON schema_.songs_artists 
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW EXECUTE FUNCTION schema_.check_song_has_artist_after_delete();



CREATE CONSTRAINT TRIGGER trg_release_must_have_song_after_delete 
AFTER UPDATE OF date_removed ON schema_.songs_releases 
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW 
WHEN (NEW.date_removed IS NOT NULL)
EXECUTE FUNCTION schema_.check_release_has_song_after_delete();



CREATE OR REPLACE FUNCTION schema_.check_main_cover_belongs_to_release()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.main_cover_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM schema_.release_covers 
            WHERE id = NEW.main_cover_id AND release_id = NEW.id
        ) THEN
            RAISE EXCEPTION 'main_cover_id must belong to this release.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_ensure_cover_match
AFTER INSERT OR UPDATE OF main_cover_id ON schema_.releases
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION schema_.check_main_cover_belongs_to_release();




CREATE OR REPLACE FUNCTION schema_.prevent_multiple_active_song_reviews()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM schema_.song_reviews sr
        JOIN schema_.reviews r ON r.id = sr.review_id
        WHERE sr.song_id = NEW.song_id 
          AND r.user_id = (SELECT user_id FROM schema_.reviews WHERE id = NEW.review_id)
          AND r.date_removed IS NULL
    ) THEN
        RAISE EXCEPTION 'User already has an active review for this song.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_single_active_song_review
BEFORE INSERT ON schema_.song_reviews
FOR EACH ROW EXECUTE FUNCTION schema_.prevent_multiple_active_song_reviews();

CREATE OR REPLACE FUNCTION schema_.prevent_multiple_active_release_reviews()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM schema_.release_reviews rr
        JOIN schema_.reviews r ON r.id = rr.review_id
        WHERE rr.release_id = NEW.release_id 
          AND r.user_id = (SELECT user_id FROM schema_.reviews WHERE id = NEW.review_id)
          AND r.date_removed IS NULL
    ) THEN
        RAISE EXCEPTION 'User already has an active review for this release.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_single_active_release_review
BEFORE INSERT ON schema_.release_reviews
FOR EACH ROW EXECUTE FUNCTION schema_.prevent_multiple_active_release_reviews();



CREATE OR REPLACE FUNCTION schema_.check_playlist_has_owner() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM schema_.playlist_owners WHERE playlist_id = NEW.id
    ) THEN
        RAISE EXCEPTION 'A playlist must have at least one owner.';
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_playlist_must_have_owner
AFTER INSERT ON schema_.playlists 
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW EXECUTE FUNCTION schema_.check_playlist_has_owner();

CREATE OR REPLACE FUNCTION schema_.check_playlist_has_owner_after_delete() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM schema_.playlist_owners WHERE playlist_id = OLD.playlist_id
    ) THEN
        RAISE EXCEPTION 'You cannot delete the last owner of a playlist.';
    END IF;
    RETURN OLD;
END
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_playlist_must_have_owner_after_delete
AFTER DELETE ON schema_.playlist_owners 
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW EXECUTE FUNCTION schema_.check_playlist_has_owner_after_delete();


CREATE OR REPLACE FUNCTION schema_.remove_like_on_owner_removal() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM schema_.playlists WHERE id = OLD.playlist_id AND is_private = true) THEN
        UPDATE schema_.playlist_likes
        SET date_removed = now()
        WHERE playlist_id = OLD.playlist_id 
          AND user_id = OLD.user_id 
          AND date_removed IS NULL;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_remove_like_on_owner_removal
AFTER DELETE ON schema_.playlist_owners
FOR EACH ROW EXECUTE FUNCTION schema_.remove_like_on_owner_removal();



CREATE OR REPLACE FUNCTION schema_.check_user_has_streaming_account_after_update() 
RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM schema_.streaming_accounts WHERE user_id = OLD.user_id
    ) THEN
        RAISE EXCEPTION 'Update failed: User (id=%) must have at least one streaming account connected.', OLD.user_id;
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_user_must_have_streaming_account_after_update 
AFTER UPDATE OF user_id ON schema_.streaming_accounts 
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW EXECUTE FUNCTION schema_.check_user_has_streaming_account_after_update();


CREATE OR REPLACE FUNCTION schema_.cascade_user_soft_delete() 
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.date_left IS NOT NULL AND OLD.date_left IS NULL THEN
        
        UPDATE schema_.song_likes SET date_removed = NEW.date_left 
        WHERE user_id = NEW.id AND date_removed IS NULL;
        
        UPDATE schema_.release_likes SET date_removed = NEW.date_left 
        WHERE user_id = NEW.id AND date_removed IS NULL;
        
        UPDATE schema_.playlist_likes SET date_removed = NEW.date_left 
        WHERE user_id = NEW.id AND date_removed IS NULL;
        
        UPDATE schema_.user_follows SET date_until = NEW.date_left 
        WHERE user_id = NEW.id AND date_until IS NULL;
        
        UPDATE schema_.artist_follows SET date_until = NEW.date_left 
        WHERE user_id = NEW.id AND date_until IS NULL;
        
        UPDATE schema_.reviews SET date_removed = NEW.date_left 
        WHERE user_id = NEW.id AND date_removed IS NULL;
        
    END IF;
    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_cascade_user_soft_delete
AFTER UPDATE OF date_left ON schema_.users
FOR EACH ROW EXECUTE FUNCTION schema_.cascade_user_soft_delete();


CREATE OR REPLACE FUNCTION schema_.check_song_has_release_after_remove() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM schema_.songs_releases 
        WHERE song_id = OLD.song_id AND date_removed IS NULL
    ) THEN
        RAISE EXCEPTION 'A song cannot be left with zero active releases.';
    END IF;
    RETURN OLD;
END
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_song_must_have_release_after_remove 
AFTER UPDATE OF date_removed ON schema_.songs_releases 
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW 
WHEN (NEW.date_removed IS NOT NULL)
EXECUTE FUNCTION schema_.check_song_has_release_after_remove();



CREATE OR REPLACE FUNCTION schema_.check_playlist_editor_is_owner() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM schema_.playlist_owners 
        WHERE playlist_id = NEW.playlist_id AND user_id = NEW.user_id
    ) THEN
        RAISE EXCEPTION 'Only verified playlist owners can add songs to this playlist.';
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_only_owners_can_edit_playlist
BEFORE INSERT ON schema_.playlist_songs
FOR EACH ROW EXECUTE FUNCTION schema_.check_playlist_editor_is_owner();

CREATE OR REPLACE FUNCTION schema_.check_main_cover_belongs_to_release()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.main_cover_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM schema_.release_covers 
            WHERE id = NEW.main_cover_id 
              AND release_id = NEW.id 
              AND used_until IS NULL 
        ) THEN
            RAISE EXCEPTION 'main_cover_id must belong to this release and cannot be an archived cover.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


CREATE OR REPLACE FUNCTION schema_.cascade_playlist_soft_delete() 
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.date_removed IS NOT NULL AND OLD.date_removed IS NULL THEN
        UPDATE schema_.playlist_songs SET date_removed = NEW.date_removed 
        WHERE playlist_id = NEW.id AND date_removed IS NULL;
        
        UPDATE schema_.playlist_likes SET date_removed = NEW.date_removed 
        WHERE playlist_id = NEW.id AND date_removed IS NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_cascade_playlist_soft_delete
AFTER UPDATE OF date_removed ON schema_.playlists
FOR EACH ROW EXECUTE FUNCTION schema_.cascade_playlist_soft_delete();


ALTER TABLE schema_.import_requests DROP CONSTRAINT cns_import_requests;
ALTER TABLE schema_.import_requests 
    ADD CONSTRAINT cns_import_requests 
    CHECK (completed_date IS NULL OR upload_date <= completed_date);




ALTER TABLE schema_.genres 
    ADD CONSTRAINT chk_no_self_subgenre CHECK (id <> subgenre_of);



ALTER TABLE schema_.playlist_likes DROP CONSTRAINT playlist_likes_possible;

CREATE OR REPLACE FUNCTION schema_.check_can_like_playlist() RETURNS trigger AS $$
BEGIN
    IF NOT schema_.can_like_playlist(NEW.playlist_id, NEW.user_id) THEN
        RAISE EXCEPTION 'User does not have permission to like this private playlist.';
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_playlist_like_permission
BEFORE INSERT OR UPDATE ON schema_.playlist_likes
FOR EACH ROW EXECUTE FUNCTION schema_.check_can_like_playlist();



COMMIT;