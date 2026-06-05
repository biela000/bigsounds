BEGIN;
CREATE TABLE schema_.artists_bands (
    artist_id integer NOT NULL REFERENCES schema_.artists(id) ON DELETE CASCADE,
    band_id integer NOT NULL REFERENCES schema_.artists(id) ON DELETE CASCADE,
    date_joined timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_left timestamp without time zone,
    CONSTRAINT chk_no_self_band CHECK (artist_id <> band_id),
    CONSTRAINT cns_artists_bands CHECK (date_left IS NULL OR date_joined < date_left),
    PRIMARY KEY (artist_id, band_id, date_joined)
);

DROP TYPE IF EXISTS public.artist_role_enum CASCADE;

DROP VIEW IF EXISTS schema_.streams_detail;

ALTER TABLE schema_.streams DROP COLUMN id;

CREATE VIEW schema_.streams_detail AS
 SELECT st.user_id,
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

ALTER TABLE schema_.songs_releases RENAME COLUMN added_date TO date_added;
ALTER TABLE schema_.songs_releases RENAME COLUMN removed_date TO date_removed;

ALTER TYPE public.import_status_enum SET SCHEMA schema_;
ALTER TYPE public.release_format_enum SET SCHEMA schema_;



DROP TABLE IF EXISTS schema_.releases_labels CASCADE;
DROP TABLE IF EXISTS schema_.labels CASCADE;

DROP FUNCTION IF EXISTS schema_.check_release_has_artist_after_delete() CASCADE;

DROP FUNCTION IF EXISTS schema_.check_release_has_song_after_delete() CASCADE;

DROP FUNCTION IF EXISTS schema_.check_song_has_artist_after_delete() CASCADE;

DROP FUNCTION IF EXISTS schema_.check_user_has_streaming_account_after_delete() CASCADE;

COMMIT;