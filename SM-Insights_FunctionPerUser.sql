use user_insights;

DELIMITER //

CREATE PROCEDURE PopulatePostsForUser(new_user_id INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE post_count INT;
    DECLARE last_post_id INT;

    -- Fetch the last post_id
    SELECT MAX(post_id) INTO last_post_id FROM Post;

    -- Randomize post count (between 30 and 100)
    SET post_count = FLOOR(RAND() * 71) + 30;

    WHILE i < post_count DO
        SET last_post_id = last_post_id + 1;

        INSERT INTO Post (post_id, user_id, post_views, post_likes, post_shares, post_comments, post_saves, post_type, post_location, hashtags)
        VALUES (
            last_post_id,
            new_user_id,
            FLOOR(RAND() * 1000000),                                 -- views
            FLOOR(RAND() * 0.2 * post_views),                         -- likes (up to 20% of views)
            FLOOR(RAND() * 0.1 * post_views),                         -- shares (up to 10% of views)
            FLOOR(RAND() * 10000),                                    -- comments (up to 10,000)
            FLOOR(RAND() * 0.05 * post_views),                        -- saves (up to 5% of views)
            IF(RAND() < 0.67, 'Reel', 'Post'),                        -- 67% chance of being 'Reel'
            ELT(FLOOR(RAND() * 30) + 1, 'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose', 'Austin', 'Jacksonville', 'Fort Worth', 'Columbus', 'Charlotte', 'San Francisco', 'Indianapolis', 'Seattle', 'Denver', 'Washington', 'Boston', 'El Paso', 'Nashville', 'Detroit', 'Las Vegas', 'Portland', 'Memphis', 'Oklahoma City', 'Louisville', 'Baltimore'),
            CONCAT_WS(' ', ELT(FLOOR(RAND() * 30) + 1, '#memes', '#viral', '#funny', '#instagood', '#love', '#photooftheday', '#fashion', '#beautiful', '#happy', '#cute', '#tbt', '#like4like', '#followme', '#picoftheday', '#follow', '#me', '#selfie', '#hotgirlsummer', '#besties', '#glowup', '#repost', '#art', '#girl', '#nature', '#smile', '#style', '#food', '#family', '#travel', '#fitness'))
        );

        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE PopulateStoriesForUser(IN user_id INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE story_count INT;
    DECLARE last_story_id INT;
    
    SELECT MAX(story_id) INTO last_story_id FROM Story;

    -- Randomly set the number of stories for the user between 1 and 5
    SET story_count = FLOOR(1 + (RAND() * 5));

    WHILE i <= story_count DO
        -- Generate random values for story views, likes, and replies
        SET last_story_id = last_story_id+1;
        SET @story_views = FLOOR(RAND() * 1000);
        SET @story_likes = FLOOR(@story_views * 0.2);  -- Likes up to 20% of views
        SET @no_of_replies = FLOOR(@story_views * 0.1); -- Replies up to 10% of views

        -- Insert the story for the user
        INSERT INTO Story (story_id, user_id, story_views, story_likes, no_of_replies)
        VALUES (
			last_story_id,
            user_id,
            @story_views,
            @story_likes,
            @no_of_replies
        );

        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE PopulateFollowersForUser(IN user_id INT)
BEGIN
    DECLARE follower_count INT DEFAULT 0;
    DECLARE follower_age INT;
    DECLARE city_name VARCHAR(20);
    DECLARE follower_username VARCHAR(25);
    
    -- Randomly set the number of followers for the user between 100 and 300
    SET follower_count = FLOOR(100 + (RAND() * 201));

    WHILE follower_count > 0 DO
        -- Generate a random username for the follower
        SET follower_username = CONCAT('Follower_', user_id, '_', follower_count);

        -- Assign a random age between 13 and 55
        SET follower_age = FLOOR(13 + (RAND() * 43));

        -- Assign a random city from the predefined Cities table
        SET city_name = (SELECT city_name FROM Cities ORDER BY RAND() LIMIT 1);

        -- Insert the follower relationship
        INSERT IGNORE INTO Follower (flr_username, user_id, city, country, gender, age)
        VALUES (
            follower_username,
            user_id,
            city_name,
            'USA',
            IF(RAND() < 0.5, 'Male', 'Female'),
            follower_age
        );

        SET follower_count = follower_count - 1;
    END WHILE;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE PopulateDMForUser(IN user_id INT)
BEGIN
    DECLARE dm_count INT DEFAULT 0;
    DECLARE sender_acc VARCHAR(25);
    DECLARE msg_category ENUM('Primary', 'General', 'Requests');
    DECLARE msg_max INT;

    -- Initialize message category counts
    DECLARE primary_count INT DEFAULT 0;
    DECLARE general_count INT DEFAULT 0;
    DECLARE requests_count INT DEFAULT 0;

    -- Loop to insert messages until the limits for each category are reached
    WHILE (primary_count < 15 OR general_count < 30 OR requests_count < 50) DO
        -- Select a random sender account name from existing users
        SET sender_acc = CONCAT('Sender_', user_id, '_', dm_count + 1);

        -- Determine message category based on remaining counts
        IF primary_count < 15 THEN
            SET msg_category = 'Primary';
            SET primary_count = primary_count + 1;
            SET msg_max = primary_count;
        ELSEIF general_count < 30 THEN
            SET msg_category = 'General';
            SET general_count = general_count + 1;
            SET msg_max = general_count;
        ELSEIF requests_count < 50 THEN
            SET msg_category = 'Requests';
            SET requests_count = requests_count + 1;
            SET msg_max = requests_count;
        END IF;

        -- Insert the DM record
        INSERT INTO DM (sender_acc, user_id, msg_category, msg_count)
        VALUES (
            sender_acc,
            user_id,
            msg_category,
            msg_max
        );

        -- Increment overall dm_count
        SET dm_count = dm_count + 1;
    END WHILE;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE PopulateBioForUser(IN user_id INT)
BEGIN
    DECLARE page_category VARCHAR(20);
    DECLARE description VARCHAR(150);

    -- Randomly assign a page category and corresponding description
    SET page_category = CASE FLOOR(RAND() * 5)
        WHEN 0 THEN 'Retail'
        WHEN 1 THEN 'Business'
        WHEN 2 THEN 'Digital Creator'
        WHEN 3 THEN 'Edutainment'
        WHEN 4 THEN 'Sports'
    END;

    SET description = CASE page_category
        WHEN 'Retail' THEN 'Discover the latest trends and top products for every season!'
        WHEN 'Business' THEN 'Empowering growth with insights, tips, and success stories.'
        WHEN 'Digital Creator' THEN 'Creating content that inspires, educates, and entertains!'
        WHEN 'Edutainment' THEN 'Where learning meets fun – explore, learn, and enjoy.'
        WHEN 'Sports' THEN 'All things sports: news, updates, and fitness motivation.'
    END;

    -- Insert the bio data for the user
    INSERT INTO Bio (user_id, description, page_category)
    VALUES (user_id, description, page_category);
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE PopulatePostInteractionsForUser()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE max_post_id INT DEFAULT 3461;
	SELECT MAX(post_id) INTO max_post_id FROM Post;
    SELECT MAX(post_id) INTO i From Post;
    SET max_post_id = max_post_id + 20;
    
    WHILE i <= max_post_id DO
        -- Insert specific follower usernames for each post_id with random timestamp and day
        INSERT INTO Post_Interactions (post_id, flr_username, timestamp, day) VALUES
            (i, 'Robin_1', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_10', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_100', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1000', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1001', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1002', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1003', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1004', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1005', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1006', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1007', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1008', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1009', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_101', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1010', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1011', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1012', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1013', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1014', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1015', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat'));

        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE PopulateStoryInteractions()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE max_story_id INT DEFAULT 201;
    DECLARE random_day ENUM('Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat');
	SELECT MAX(story_id) INTO max_story_id FROM Post;
    SELECT MAX(story_id) INTO i From Post;
    SET max_story_id = max_story_id + 20;
    
    WHILE i <= max_story_id DO
        -- Insert specific follower usernames for each story_id with random timestamp and day
        INSERT INTO Story_interactions (story_id, flr_username, timestamp, day) VALUES
            (i, 'Robin_1', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_10', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_100', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1000', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1001', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1002', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1003', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1004', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1005', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1006', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1007', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1008', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1009', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_101', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1010', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1011', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1012', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1013', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1014', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat')),
            (i, 'Robin_1015', CURRENT_TIMESTAMP - INTERVAL FLOOR(RAND() * 365) DAY + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE, ELT(FLOOR(RAND() * 7) + 1, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat'));

        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;








