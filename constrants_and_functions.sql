ALTER TABLE schema_.reviews 
ADD CONSTRAINT chk_score_range CHECK (score BETWEEN 1 AND 10);

ALTER TABLE schema_.user_follows 
ADD CONSTRAINT chk_no_self_follow CHECK (user_id != followed_user_id);

ALTER TABLE schema_.artists_aliases 
ADD CONSTRAINT chk_alias_not_empty CHECK (TRIM(artist_alias) != '');

ALTER TABLE schema_.playlists 
ADD CONSTRAINT chk_playlist_name_length CHECK (LENGTH(TRIM(name)) > 0);

CREATE OR REPLACE FUNCTION schema_.get_recommended_songs(
    p_user_id integer, 
    p_limit integer DEFAULT 10
)
RETURNS TABLE (
    song_id integer,
    song_title varchar,
    recommendation_score bigint
) 
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

CREATE OR REPLACE FUNCTION schema_.get_user_top_songs(
    p_user_id integer,
    p_days_back integer DEFAULT 30,
    p_limit integer DEFAULT 10
)
RETURNS TABLE (
    song_id integer,
    song_title varchar,
    play_count bigint
) 
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
      AND str.stream_timestamp >= (CURRENT_TIMESTAMP - (p_days_back || ' days')::interval)
    GROUP BY s.id, s.title
    ORDER BY play_count DESC
    LIMIT p_limit;
END;
$$;

CREATE OR REPLACE FUNCTION schema_.get_release_rating(
    p_release_id integer
)
RETURNS TABLE (
    average_score numeric,
    total_reviews bigint
) 
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

CREATE OR REPLACE FUNCTION schema_.get_friends_activity_feed(
    p_user_id integer,
    p_limit integer DEFAULT 30
)
RETURNS TABLE (
    friend_id integer,
    friend_name text,
    activity_type text, 
    item_title text,
    activity_date timestamp
) 
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

