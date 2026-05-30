CREATE VIEW v_song_details AS
SELECT 
    s.*,
    sa.artist_id,
    a.stage_name,
    sr.release_id,
    r.title release_title
FROM schema_.songs s
JOIN schema_.songs_artists sa ON s.id = sa.song_id
JOIN schema_.artists a ON sa.artist_id = a.id
JOIN schema_.songs_releases sr ON s.id = sr.song_id
JOIN schema_.releases r ON sr.release_id = r.id;



CREATE OR REPLACE FUNCTION schema_.get_user_listening_stats_by_count(time_period INTERVAL DEFAULT NULL)
RETURNS TABLE (
    user_id INTEGER,
    top_song_id INTEGER,
    top_artist_id INTEGER,
    top_release_id INTEGER,
    top_genre_id INTEGER
) AS 
$$
BEGIN
    RETURN QUERY
    WITH filtered_streams AS (
        SELECT s.user_id, s.song_id
        FROM schema_.streams s
        WHERE time_period IS NULL OR s.stream_timestamp >= NOW() - time_period
    ),
    top_songs AS (
        SELECT DISTINCT ON (fs.user_id) fs.user_id, fs.song_id
        FROM filtered_streams fs
        GROUP BY fs.user_id, fs.song_id
        ORDER BY fs.user_id, COUNT(*) DESC
    ),
    top_artists AS (
        SELECT DISTINCT ON (fs.user_id) fs.user_id, sa.artist_id
        FROM filtered_streams fs
        JOIN schema_.songs_artists sa ON fs.song_id = sa.song_id
        GROUP BY fs.user_id, sa.artist_id
        ORDER BY fs.user_id, COUNT(*) DESC
    ),
    top_releases AS (
        SELECT DISTINCT ON (fs.user_id) fs.user_id, sr.release_id
        FROM filtered_streams fs
        JOIN schema_.songs_releases sr ON fs.song_id = sr.release_id
        GROUP BY fs.user_id, sr.release_id
        ORDER BY fs.user_id, COUNT(*) DESC
    ),
    top_genres AS (
        SELECT DISTINCT ON (fs.user_id) fs.user_id, sg.genre_id
        FROM filtered_streams fs
        JOIN schema_.songs_genres sg ON fs.song_id = sg.genre_id
        GROUP BY fs.user_id, sg.genre_id
        ORDER BY fs.user_id, COUNT(*) DESC
    )
    SELECT 
        u.id AS user_id,
        ts.song_id AS top_song_id,
        ta.artist_id AS top_artist_id,
        tr.release_id AS top_release_id,
        tg.genre_id AS top_genre_id
    FROM schema_.users u
    LEFT JOIN top_songs ts ON u.id = ts.user_id
    LEFT JOIN top_artists ta ON u.id = ta.user_id
    LEFT JOIN top_releases tr ON u.id = tr.user_id
    LEFT JOIN top_genres tg ON u.id = tg.user_id
    WHERE ts.song_id IS NOT NULL 
       OR ta.artist_id IS NOT NULL 
       OR tr.release_id IS NOT NULL 
       OR tg.genre_id IS NOT NULL;
END;
$$
LANGUAGE plpgsql STABLE;



CREATE MATERIALIZED VIEW v_one_week_user_listening_stats_by_count AS
SELECT * FROM schema_.get_user_listening_stats_by_count(INTERVAL '7 days');

CREATE MATERIALIZED VIEW v_four_weeks_user_listening_stats_by_count AS
SELECT * FROM schema_.get_user_listening_stats_by_count(INTERVAL '28 days');

CREATE MATERIALIZED VIEW v_six_months_user_listening_stats_by_count AS
SELECT * FROM schema_.get_user_listening_stats_by_count(INTERVAL '6 months');

CREATE MATERIALIZED VIEW v_one_year_user_listening_stats_by_count AS
SELECT * FROM schema_.get_user_listening_stats_by_count(INTERVAL '1 year');

CREATE MATERIALIZED VIEW v_lifetime_user_listening_stats_by_count AS
SELECT * FROM schema_.get_user_listening_stats_by_count(NULL);