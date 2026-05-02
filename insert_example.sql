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

INSERT INTO schema_.songs (id, title, duration) VALUES 
(1, 'Let It Be', '4 minutes 3 seconds'),
(2, 'Get Lucky', '6 minutes 9 seconds');

INSERT INTO schema_.playlists (id, is_visible, name) VALUES 
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

INSERT INTO schema_.songs_artists (song_id, artist_id) VALUES 
(1, 1),
(2, 2);

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

INSERT INTO schema_.playlists_owners (playlist_id, user_id) VALUES (1, 1), (2, 2);
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