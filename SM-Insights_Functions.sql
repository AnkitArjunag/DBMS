
-- #1 Display user info
DELIMITER //

CREATE PROCEDURE GetUserInfo(IN input_user_id INT)
BEGIN
    DECLARE user_age INT;
    
    -- Calculate age based on DOB
    SELECT fname, lname, 
           TIMESTAMPDIFF(YEAR, DOB, CURDATE()) AS age, 
           bio.page_category
    FROM User
    JOIN Bio AS bio ON User.user_id = bio.user_id
    WHERE User.user_id = input_user_id;
END //

DELIMITER ;

CALL GetUserInfo(42);

-- #2 Find the total number of followers:
DELIMITER //

CREATE FUNCTION GetFollowerCount(input_user_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE follower_count INT;

    -- Calculate the total number of followers for the given user_id
    SELECT COUNT(*) INTO follower_count
    FROM Follower
    WHERE user_id = input_user_id;

    RETURN follower_count;
END //

DELIMITER ;

-- SELECT GetFollowerCount(50);  -- Example for user_id = 1

-- #3 Follower demographics analysis

DROP PROCEDURE GetFollowerStats;
DELIMITER //

CREATE PROCEDURE GetFollowerStats(IN input_user_id INT)
BEGIN
    -- Table 1: Top 4 cities by follower count, with "Other" for the remaining cities
    SELECT city, follower_count FROM (
        SELECT city, COUNT(*) AS follower_count
        FROM Follower
        WHERE user_id = input_user_id
        GROUP BY city
        ORDER BY follower_count DESC
        LIMIT 4
    ) AS TopCities
    UNION ALL
    SELECT 'Other' AS city, SUM(follower_count) AS follower_count FROM (
        SELECT city, COUNT(*) AS follower_count
        FROM Follower
        WHERE user_id = input_user_id
        GROUP BY city
        ORDER BY follower_count DESC
        LIMIT 4, 18446744073709551615  -- Skips the top 4, includes all others
    ) AS OtherCities;

    -- Table 2: Followers grouped by gender
    SELECT gender, COUNT(*) AS follower_count
    FROM Follower
    WHERE user_id = input_user_id
    GROUP BY gender;

    -- Table 3: Followers grouped by age ranges
    SELECT 
        CASE
            WHEN age BETWEEN 13 AND 18 THEN '13-18'
            WHEN age BETWEEN 19 AND 25 THEN '19-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 45 THEN '36-45'
            WHEN age BETWEEN 46 AND 55 THEN '46-55'
            ELSE 'Other'
        END AS age_range,
        COUNT(*) AS follower_count
    FROM Follower
    WHERE user_id = input_user_id
    GROUP BY age_range;
END //

DELIMITER ;

-- CALL GetFollowerStats(44);

-- #4 Reach
DELIMITER //

CREATE PROCEDURE GetUserPostMetrics(IN input_user_id INT)
BEGIN
    DECLARE total_reach INT DEFAULT 0;
    DECLARE post_interactions INT DEFAULT 0;

    -- Calculate total reach as the sum of post_views for the user's posts
    SELECT SUM(post_views)
    INTO total_reach
    FROM Post
    WHERE user_id = input_user_id;

    -- Calculate total post interactions (likes, saves, comments, shares)
    SELECT SUM(post_likes + post_saves + post_comments + post_shares)
    INTO post_interactions
    FROM Post
    WHERE user_id = input_user_id;

    -- Display total reach and interactions summary
    SELECT total_reach AS Total_Reach, post_interactions AS Post_Interactions;

    -- Display total reach grouped by post_location, with top 4 locations and 'Other'
    -- Step 1: Get the top 4 locations
    CREATE TEMPORARY TABLE TopLocations AS
    SELECT post_location, SUM(post_views) AS Location_Reach
    FROM Post
    WHERE user_id = input_user_id
    GROUP BY post_location
    ORDER BY Location_Reach DESC
    LIMIT 4;

    -- Display top 4 locations
    SELECT post_location, Location_Reach
    FROM TopLocations;

    -- Step 2: Calculate "Other" reach
    SELECT 'Other' AS post_location, SUM(post_views) AS Location_Reach
    FROM Post
    WHERE user_id = input_user_id
      AND post_location NOT IN (SELECT post_location FROM TopLocations);

    -- Display total reach grouped by post_type
    SELECT post_type, SUM(post_views) AS Type_Reach
    FROM Post
    WHERE user_id = input_user_id
    GROUP BY post_type
    ORDER BY Type_Reach DESC;

    -- Clean up temporary table
    DROP TEMPORARY TABLE IF EXISTS TopLocations;

END //

DELIMITER ;

CALL GetUserPostMetrics(31);

-- #5 Hashtag effectiveness lookup

DELIMITER //

CREATE PROCEDURE GetHashtagMetrics(IN input_user_id INT, IN input_hashtag VARCHAR(50))
BEGIN
    DECLARE total_posts INT DEFAULT 0;
    DECLARE used_in INT DEFAULT 0;
    DECLARE total_views INT DEFAULT 0;
    DECLARE hash_views INT DEFAULT 0;

    -- Count total posts for the user
    SELECT COUNT(*)
    INTO total_posts
    FROM Post
    WHERE user_id = input_user_id;

    -- Count posts where the specific hashtag is used and calculate cumulative views for these posts
    SELECT COUNT(*) AS used_in_count, IFNULL(SUM(post_views), 0) AS hashtag_views
    INTO used_in, hash_views
    FROM Post
    WHERE user_id = input_user_id
      AND FIND_IN_SET(input_hashtag, hashtags) > 0;

    -- Calculate total views for all posts by the user
    SELECT SUM(post_views)
    INTO total_views
    FROM Post
    WHERE user_id = input_user_id;

    -- Display results
    SELECT total_posts AS Total_Posts,
           used_in AS Used_In,
           total_views AS Total_Views,
           hash_views AS Hash_Views;
END //

DELIMITER ;

CALL GetHashtagMetrics(5,"#hotgirlsummer");

-- #6 Most active times
DELIMITER //

CREATE PROCEDURE GetTotalReachGrouped(IN input_user_id INT)
BEGIN
    -- First table: Total views grouped by day
    SELECT 
        pi.day AS Day,
        SUM(p.post_views) AS Total_Reach
    FROM 
        Post_Interactions pi
    JOIN 
        Post p ON pi.post_id = p.post_id
    WHERE 
        p.user_id = input_user_id
    GROUP BY 
        Day
    ORDER BY 
        FIELD(Day, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat');

    -- Second table: Total views grouped by 3-hour timestamp intervals
    SELECT 
        CASE 
            WHEN HOUR(pi.timestamp) BETWEEN 0 AND 2 THEN '12a-3a'
            WHEN HOUR(pi.timestamp) BETWEEN 3 AND 5 THEN '3a-6a'
            WHEN HOUR(pi.timestamp) BETWEEN 6 AND 8 THEN '6a-9a'
            WHEN HOUR(pi.timestamp) BETWEEN 9 AND 11 THEN '9a-12p'
            WHEN HOUR(pi.timestamp) BETWEEN 12 AND 14 THEN '12p-3p'
            WHEN HOUR(pi.timestamp) BETWEEN 15 AND 17 THEN '3p-6p'
            WHEN HOUR(pi.timestamp) BETWEEN 18 AND 20 THEN '6p-9p'
            WHEN HOUR(pi.timestamp) BETWEEN 21 AND 23 THEN '9p-12a'
        END AS Time_Interval,
        SUM(p.post_views) AS Total_Reach
    FROM 
        Post_Interactions pi
    JOIN 
        Post p ON pi.post_id = p.post_id
    WHERE 
        p.user_id = input_user_id
    GROUP BY 
        Time_Interval
    ORDER BY 
        Time_Interval;
END //

DELIMITER ;

CALL GetTotalReachGrouped(5);

-- #7 Story Insights

DELIMITER //

CREATE PROCEDURE GetUserStoryMetrics(IN input_user_id INT)
BEGIN
    -- Step 1: Calculate Story Reach (sum of story_views for all stories by user)
    SELECT SUM(story_views) AS story_reach
    INTO @story_reach
    FROM Story
    WHERE user_id = input_user_id;

    -- Step 2: Calculate Story Interactions (total likes and replies)
    SELECT SUM(story_likes) + SUM(no_of_replies) AS story_interactions
    INTO @story_interactions
    FROM Story
    WHERE user_id = input_user_id;

    -- Step 3: Calculate Story Reach by Day
    SELECT si.day, SUM(s.story_views) AS day_reach
    FROM Story s
    JOIN Story_Interactions si ON s.story_id = si.story_id
    WHERE s.user_id = input_user_id
    GROUP BY si.day
    ORDER BY 
        FIELD(si.day, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat');

    -- Step 4: Calculate Story Reach by Time Interval
    SELECT 
        CASE 
            WHEN HOUR(si.timestamp) >= 0 AND HOUR(si.timestamp) < 3 THEN '12a-3a'
            WHEN HOUR(si.timestamp) >= 3 AND HOUR(si.timestamp) < 6 THEN '3a-6a'
            WHEN HOUR(si.timestamp) >= 6 AND HOUR(si.timestamp) < 9 THEN '6a-9a'
            WHEN HOUR(si.timestamp) >= 9 AND HOUR(si.timestamp) < 12 THEN '9a-12p'
            WHEN HOUR(si.timestamp) >= 12 AND HOUR(si.timestamp) < 15 THEN '12p-3p'
            WHEN HOUR(si.timestamp) >= 15 AND HOUR(si.timestamp) < 18 THEN '3p-6p'
            WHEN HOUR(si.timestamp) >= 18 AND HOUR(si.timestamp) < 21 THEN '6p-9p'
            ELSE '9p-12a'
        END AS time_interval,
        SUM(s.story_views) AS interval_reach
    FROM Story s
    JOIN Story_Interactions si ON s.story_id = si.story_id
    WHERE s.user_id = input_user_id
    GROUP BY time_interval
    ORDER BY 
        FIELD(time_interval, '12a-3a', '3a-6a', '6a-9a', '9a-12p', '12p-3p', '3p-6p', '6p-9p', '9p-12a');
    
    -- Output total story reach and interactions as well
    SELECT @story_reach AS story_reach, @story_interactions AS story_interactions;
END //

DELIMITER ;

CALL GetUserStoryMetrics(41);

-- #8 DM awareness
DELIMITER //

CREATE PROCEDURE GetUserDMs(IN input_user_id INT)
BEGIN
    -- Step 1: Calculate total number of DMs for the user
    SELECT COUNT(*) AS total_dms
    FROM DM
    WHERE user_id = input_user_id;

    -- Step 2: Calculate total number of DMs grouped by category
    SELECT msg_category, COUNT(*) AS category_count
    FROM DM
    WHERE user_id = input_user_id
    GROUP BY msg_category
    ORDER BY FIELD(msg_category, 'Primary', 'General', 'Requests');
END //

DELIMITER ;

CALL GetUserDMs(40);

-- #9 Trends : Hashtags

DELIMITER //

CREATE PROCEDURE GetTopHashtags()
BEGIN
    -- Step 1: Calculate total views for each hashtag in the specified list
    SELECT 
        hashtag, 
        SUM(post_views) AS total_views
    FROM (
        SELECT '#memes' AS hashtag, SUM(post_views) AS post_views FROM Post WHERE hashtags LIKE '%#memes%'
        UNION ALL
        SELECT '#viral', SUM(post_views) FROM Post WHERE hashtags LIKE '%#viral%'
        UNION ALL
        SELECT '#funny', SUM(post_views) FROM Post WHERE hashtags LIKE '%#funny%'
        UNION ALL
        SELECT '#instagood', SUM(post_views) FROM Post WHERE hashtags LIKE '%#instagood%'
        UNION ALL
        SELECT '#love', SUM(post_views) FROM Post WHERE hashtags LIKE '%#love%'
        UNION ALL
        SELECT '#photooftheday', SUM(post_views) FROM Post WHERE hashtags LIKE '%#photooftheday%'
        UNION ALL
        SELECT '#fashion', SUM(post_views) FROM Post WHERE hashtags LIKE '%#fashion%'
        UNION ALL
        SELECT '#beautiful', SUM(post_views) FROM Post WHERE hashtags LIKE '%#beautiful%'
        UNION ALL
        SELECT '#happy', SUM(post_views) FROM Post WHERE hashtags LIKE '%#happy%'
        UNION ALL
        SELECT '#cute', SUM(post_views) FROM Post WHERE hashtags LIKE '%#cute%'
        UNION ALL
        SELECT '#tbt', SUM(post_views) FROM Post WHERE hashtags LIKE '%#tbt%'
        UNION ALL
        SELECT '#like4like', SUM(post_views) FROM Post WHERE hashtags LIKE '%#like4like%'
        UNION ALL
        SELECT '#followme', SUM(post_views) FROM Post WHERE hashtags LIKE '%#followme%'
        UNION ALL
        SELECT '#picoftheday', SUM(post_views) FROM Post WHERE hashtags LIKE '%#picoftheday%'
        UNION ALL
        SELECT '#follow', SUM(post_views) FROM Post WHERE hashtags LIKE '%#follow%'
        UNION ALL
        SELECT '#me', SUM(post_views) FROM Post WHERE hashtags LIKE '%#me%'
        UNION ALL
        SELECT '#selfie', SUM(post_views) FROM Post WHERE hashtags LIKE '%#selfie%'
        UNION ALL
        SELECT '#hotgirlsummer', SUM(post_views) FROM Post WHERE hashtags LIKE '%#hotgirlsummer%'
        UNION ALL
        SELECT '#besties', SUM(post_views) FROM Post WHERE hashtags LIKE '%#besties%'
        UNION ALL
        SELECT '#glowup', SUM(post_views) FROM Post WHERE hashtags LIKE '%#glowup%'
        UNION ALL
        SELECT '#repost', SUM(post_views) FROM Post WHERE hashtags LIKE '%#repost%'
        UNION ALL
        SELECT '#art', SUM(post_views) FROM Post WHERE hashtags LIKE '%#art%'
        UNION ALL
        SELECT '#girl', SUM(post_views) FROM Post WHERE hashtags LIKE '%#girl%'
        UNION ALL
        SELECT '#nature', SUM(post_views) FROM Post WHERE hashtags LIKE '%#nature%'
        UNION ALL
        SELECT '#smile', SUM(post_views) FROM Post WHERE hashtags LIKE '%#smile%'
        UNION ALL
        SELECT '#style', SUM(post_views) FROM Post WHERE hashtags LIKE '%#style%'
        UNION ALL
        SELECT '#food', SUM(post_views) FROM Post WHERE hashtags LIKE '%#food%'
        UNION ALL
        SELECT '#family', SUM(post_views) FROM Post WHERE hashtags LIKE '%#family%'
        UNION ALL
        SELECT '#travel', SUM(post_views) FROM Post WHERE hashtags LIKE '%#travel%'
        UNION ALL
        SELECT '#fitness', SUM(post_views) FROM Post WHERE hashtags LIKE '%#fitness%'
    ) AS HashtagViews
    GROUP BY hashtag
    ORDER BY total_views DESC
    LIMIT 5;
END //

DELIMITER ;

CALL GetTopHashtags();

-- #10 Trends : Locations

DELIMITER //

CREATE PROCEDURE GetTopLocations()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE city VARCHAR(50);
    DECLARE city_views INT;
    
    -- Cursor to iterate through cities in the Cities table
    DECLARE city_cursor CURSOR FOR 
        SELECT city_name FROM Cities;

    -- Exit handler for the cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Temporary table to store the results
    CREATE TEMPORARY TABLE IF NOT EXISTS LocationViews (
        city_name VARCHAR(50),
        total_views INT
    );

    -- Open the cursor
    OPEN city_cursor;

    -- Loop through each city
    read_loop: LOOP
        FETCH city_cursor INTO city;
        
        -- Exit the loop if no more rows
        IF done THEN 
            LEAVE read_loop;
        END IF;
        
        -- Calculate total views for the current city
        SET city_views = (
            SELECT SUM(post_views) 
            FROM Post 
            WHERE post_location LIKE CONCAT('%', city, '%')
        );

        -- Insert the result into the temporary table
        INSERT INTO LocationViews (city_name, total_views)
        VALUES (city, IFNULL(city_views, 0));
    END LOOP;

    -- Close the cursor
    CLOSE city_cursor;

    -- Select top 5 locations by views
    SELECT city_name, total_views
    FROM LocationViews
    ORDER BY total_views DESC
    LIMIT 5;

    -- Drop the temporary table
    DROP TEMPORARY TABLE IF EXISTS LocationViews;
END //

DELIMITER ;

CALL GetTopLocations();


DELIMITER //

-- CREATE PROCEDURE AddNewUser(
--     IN fname VARCHAR(50),
--     IN lname VARCHAR(50),
--     IN dob DATE
-- )
-- BEGIN
--     DECLARE last_user_id INT;
--     DECLARE new_user_id INT;
--     DECLARE random_acc_type ENUM('Creator', 'Business');

--     -- Fetch the last user_id
--     SELECT MAX(user_id) INTO last_user_id FROM User;
--     SET new_user_id = last_user_id + 1;

--     -- Generate a random account type
--     SET random_acc_type = IF(RAND() < 0.67, 'Creator', 'Business');

--     -- Insert into User table
--     INSERT INTO User (user_id, fname, lname, DOB, acc_type)
--     VALUES (new_user_id, fname, lname, dob, random_acc_type);

--     -- Populate Posts for the new user
--     CALL PopulatePostsForUser(new_user_id);

--     -- Populate Stories for the new user
--     CALL PopulateStoriesForUser(new_user_id);

--     -- Populate Followers for the new user
--     CALL PopulateFollowersForUser(new_user_id);

--     -- Populate DM for the new user
--     CALL PopulateDMForUser(new_user_id);

--     -- Populate Bio for the new user
--     CALL PopulateBioForUser(new_user_id);

--     -- Populate Post Interactions for the new user
--     -- CALL PopulatePostInteractionsForUser();

--     -- Populate Story Interactions for the new user
--     -- CALL PopulateStoryInteractionsForUser();
-- END //

DELIMITER ;
CALL AddNewUser('John', 'Smith', '1990-05-15','Creator');

use user_insights;

DELIMITER //
DROP procedure if exists AddNewUser;
CREATE PROCEDURE AddNewUser(
    IN fname VARCHAR(50),
    IN lname VARCHAR(50),
    IN dob DATE,
    IN acc_type ENUM('Creator', 'Business')
)
BEGIN
    DECLARE last_user_id INT;
    DECLARE new_user_id INT;

    -- Fetch the last user_id
    SELECT MAX(user_id) INTO last_user_id FROM User;
    SET new_user_id = last_user_id + 1;

    -- Insert into User table with provided parameters
    INSERT INTO User (user_id, fname, lname, DOB, acc_type)
    VALUES (new_user_id, fname, lname, dob, acc_type);

    -- Populate Posts for the new user
    CALL PopulatePostsForUser(new_user_id);

    -- Populate Stories for the new user
    CALL PopulateStoriesForUser(new_user_id);

    -- Populate Followers for the new user
    CALL PopulateFollowersForUser(new_user_id);

    -- Populate DM for the new user
    CALL PopulateDMForUser(new_user_id);

    -- Populate Bio for the new user
    CALL PopulateBioForUser(new_user_id);

    -- Populate Post Interactions for the new user
    -- CALL PopulatePostInteractionsForUser();

    -- Populate Story Interactions for the new user
    -- CALL PopulateStoryInteractionsForUser();
END //

DELIMITER ;

CALL AddNewUser('John', 'Smith', '1990-05-15','Creator');


DELIMITER //

CREATE PROCEDURE AddNewUser(
    IN fname VARCHAR(50),
    IN lname VARCHAR(50),
    IN dob DATE,
    IN acc_type ENUM('Creator', 'Business')
)
BEGIN
    DECLARE new_user_id INT;

    -- Assign a new user_id by incrementing the max existing user_id
    SELECT IFNULL(MAX(user_id), 0) + 1 INTO new_user_id FROM User;

    -- Insert into User table with provided parameters
    INSERT INTO User (user_id, fname, lname, DOB, acc_type)
    VALUES (new_user_id, fname, lname, dob, acc_type);

    -- Populate Posts for the new user
    CALL PopulatePostsForUser(new_user_id);

    -- Populate Stories for the new user
    CALL PopulateStoriesForUser(new_user_id);

    -- Populate Followers for the new user
    CALL PopulateFollowersForUser(new_user_id);

    -- Populate DM for the new user
    CALL PopulateDMForUser(new_user_id);

    -- Populate Bio for the new user
    CALL PopulateBioForUser(new_user_id);

    -- Populate Post Interactions for the new user
    -- CALL PopulatePostInteractionsForUser();

    -- Populate Story Interactions for the new user
    -- CALL PopulateStoryInteractionsForUser();
END //

DELIMITER ;

CALL AddNewUser('Alice', 'Johnson', '1995-07-20', 'Business');