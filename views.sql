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


CREATE VIEW v_user_listening_stats_by_count AS
SELECT user_id, 
FROM schema_.streams
