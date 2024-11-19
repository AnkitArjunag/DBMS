    -- #1 PopulateUsers

    DELIMITER //

    CREATE PROCEDURE PopulateUsers()
    BEGIN
        DECLARE i INT DEFAULT 1;
        DECLARE follower_count INT;

        WHILE i <= 50 DO
            -- Randomize follower count and account type
            SET follower_count = FLOOR(RAND() * 5000000);
            
            INSERT INTO User(user_id, fname, lname, DOB, acc_type)
            VALUES (
                i,
                CONCAT('John', i),
                CONCAT('Doe', i),
                DATE_ADD('1950-01-01', INTERVAL FLOOR(RAND() * 22265) DAY),
                IF(RAND() > 0.3, 'Creator', 'Business')
            );
            
            SET i = i + 1;
        END WHILE;
    END

    DELIMITER ;

    CALL PopulateUsers();

    -- #2 Populate Posts table

    CREATE TABLE Cities (
        city_id INT PRIMARY KEY AUTO_INCREMENT,
        city_name VARCHAR(50)
    );

    INSERT INTO Cities (city_name) VALUES
        ('New York'), ('Los Angeles'), ('Chicago'), ('Houston'), ('Phoenix'),
        ('Philadelphia'), ('San Antonio'), ('San Diego'), ('Dallas'), ('San Jose'),
        ('Austin'), ('Jacksonville'), ('Fort Worth'), ('Columbus'), ('Charlotte'),
        ('San Francisco'), ('Indianapolis'), ('Seattle'), ('Denver'), ('Washington'),
        ('Boston'), ('El Paso'), ('Nashville'), ('Detroit'), ('Las Vegas'),
        ('Portland'), ('Memphis'), ('Oklahoma City'), ('Louisville'), ('Baltimore');
        
    CREATE TABLE Hashtags (hashtag VARCHAR(50));
    INSERT INTO Hashtags (hashtag) VALUES
        ('#memes'), ('#viral'), ('#funny'), ('#instagood'), ('#love'), ('#photooftheday'),
        ('#fashion'), ('#beautiful'), ('#happy'), ('#cute'), ('#tbt'), ('#like4like'),
        ('#followme'), ('#picoftheday'), ('#follow'), ('#me'), ('#selfie'), ('#hotgirlsummer'),
        ('#besties'), ('#glowup'), ('#repost'), ('#art'), ('#girl'), ('#nature'),
        ('#smile'), ('#style'), ('#food'), ('#family'), ('#travel'), ('#fitness');
        
    -- DESC Post;
    -- Assuming Cities and Hashtags tables are already populated as described.

    -- Generate Posts
    DELIMITER //

    CREATE PROCEDURE PopulatePosts()
    BEGIN
        DECLARE user INT;
        DECLARE post_count INT;
        DECLARE rand_views INT;
        DECLARE rand_likes INT;
        DECLARE rand_shares INT;
        DECLARE rand_comments INT;
        DECLARE rand_saves INT;
        DECLARE post_type ENUM('Post', 'Reel');
        DECLARE post_location VARCHAR(50);
        DECLARE chosen_hashtags VARCHAR(400);

        SET user = 1;

        WHILE user <= 50 DO
            SET post_count = FLOOR(RAND() * (100 - 30 + 1)) + 30;  -- 30 to 100 posts per user
            
            WHILE post_count > 0 DO
                -- Randomize post statistics
                SET rand_views = FLOOR(RAND() * 1000000);  -- 0 to 1 million views
                SET rand_likes = FLOOR(rand_views * (RAND() * 0.2));  -- likes are up to 20% of views
                SET rand_shares = FLOOR(rand_views * (RAND() * 0.1));  -- shares up to 10% of views
                SET rand_comments = FLOOR(RAND() * 10000);  -- 0 to 10,000 comments
                SET rand_saves = FLOOR(rand_views * (RAND() * 0.07));  -- saves up to 7% of views
                
                -- Randomize post type
                SET post_type = IF(RAND() < 0.33, 'Post', 'Reel');

                -- Randomize post location
                SET post_location = (SELECT city_name FROM Cities ORDER BY RAND() LIMIT 1);

                -- Generate hashtags, ensuring #hotgirlsummer is in at least half of posts
                IF RAND() < 0.5 THEN
                    SET chosen_hashtags = CONCAT('#hotgirlsummer, ',
                        (SELECT GROUP_CONCAT(hashtag SEPARATOR ', ')
                        FROM (SELECT hashtag FROM Hashtags WHERE hashtag <> '#hotgirlsummer' ORDER BY RAND() LIMIT 4) AS temp));
                ELSE
                    SET chosen_hashtags = (SELECT GROUP_CONCAT(hashtag SEPARATOR ', ')
                        FROM (SELECT hashtag FROM Hashtags ORDER BY RAND() LIMIT 5) AS temp);
                END IF;

                -- Insert the post
                INSERT INTO Post (user_id, post_views, post_likes, post_shares, post_comments, post_saves, post_type, post_location, hashtags)
                VALUES (user, rand_views, rand_likes, rand_shares, rand_comments, rand_saves, post_type, post_location, chosen_hashtags);

                SET post_count = post_count - 1;
            END WHILE;

            SET user = user + 1;
        END WHILE;
    END 

    DELIMITER ;

    -- Run the procedure to populate the posts
    CALL PopulatePosts();
    -- DROP PROCEDURE PopulatePosts;

    -- DROP TABLE Cities;

    -- #3 Populate Followers table

    DELIMITER 

    CREATE PROCEDURE PopulateFollowers()
    BEGIN
        DECLARE user INT;
        DECLARE follower_count INT;
        DECLARE follower_num INT;
        DECLARE follower_username VARCHAR(25);
        DECLARE follower_gender ENUM('Male', 'Female');
        DECLARE follower_city VARCHAR(20);
        DECLARE follower_country VARCHAR(20);
        DECLARE follower_age INT;

        SET user = 1;
        SET follower_num = 1;

        WHILE user <= 50 DO
            -- Each user has between 100 and 300 followers
            SET follower_count = FLOOR(RAND() * (300 - 100 + 1)) + 100;

            WHILE follower_count > 0 DO
                -- Assign unique username like Robin_1, Robin_2, etc.
                SET follower_username = CONCAT('Robin_', follower_num);
                SET follower_gender = IF(RAND() < 0.5, 'Male', 'Female');  -- Random gender
                SET follower_city = (SELECT city_name FROM Cities ORDER BY RAND() LIMIT 1);  -- Random city
                SET follower_country = 'USA';  -- Country set to 'USA' as cities are U.S.-based
                SET follower_age = FLOOR(RAND() * (55 - 13 + 1)) + 13;  -- Random age between 13 and 55

                -- Insert the follower record
                INSERT INTO Follower (flr_username, user_id, city, country, gender, age)
                VALUES (follower_username, user, follower_city, follower_country, follower_gender, follower_age);

                SET follower_count = follower_count - 1;
                SET follower_num = follower_num + 1;
            END WHILE;

            SET user = user + 1;
        END WHILE;
    END 

    DELIMITER ;

    CALL PopulateFollowers();

    -- #4 Populate Story Table

    -- Run the procedure to populate stories
    -- DROP PROCEDURE PopulateStories;

    DELIMITER 

    CREATE PROCEDURE PopulateStories()
    BEGIN
        DECLARE user INT DEFAULT 1;
        DECLARE story_count INT;
        DECLARE rand_views INT;
        DECLARE rand_likes INT;
        DECLARE rand_replies INT;
        DECLARE current_story_id INT DEFAULT 1;  -- Initialize the story_id counter

        WHILE user <= 50 DO
            -- Generate a random number of stories (between 3 and 5) for each user
            SET story_count = FLOOR(RAND() * (5 - 3 + 1)) + 3;

            WHILE story_count > 0 DO
                -- Generate random values for views, likes, and replies
                SET rand_views = FLOOR(RAND() * 1000);  -- Views range from 0 to 100,000
                SET rand_likes = FLOOR(rand_views * (RAND() * 0.2));  -- Likes up to 40% of views
                SET rand_replies = FLOOR(RAND() * 14);  -- Replies range from 0 to 1,000

                -- Insert the story with a manually incremented story_id
                INSERT INTO Story (story_id, user_id, story_views, story_likes, no_of_replies)
                VALUES (current_story_id, user, rand_views, rand_likes, rand_replies);

                -- Increment the story_id and reduce the story count for the current user
                SET current_story_id = current_story_id + 1;
                SET story_count = story_count - 1;
            END WHILE;

            -- Move to the next user
            SET user = user + 1;
        END WHILE;
    END 

    -- Reset delimiter back to default
    DELIMITER ;

    -- Call the procedure to populate stories
    CALL PopulateStories();

    -- #5 Populate DM table

    DELIMITER 

    CREATE PROCEDURE PopulateDMs()
    BEGIN
        DECLARE user INT DEFAULT 1;
        DECLARE dm_count INT;
        DECLARE msg_count INT;
        DECLARE sender_num INT DEFAULT 1;
        DECLARE msg_category ENUM('Primary', 'General', 'Requests');
        DECLARE sender_acc VARCHAR(25);

        WHILE user <= 50 DO
            -- Populate Primary DMs (up to 15 per user)
            SET dm_count = FLOOR(RAND() * 16);  -- Random count between 0 and 15
            SET msg_category = 'Primary';
            
            WHILE dm_count > 0 DO
                -- Generate sender account name
                SET sender_acc = CONCAT('Sender_', sender_num);
                SET msg_count = FLOOR(RAND() * 101);  -- Random message count between 0 and 100
                
                -- Insert DM entry
                INSERT INTO DM (sender_acc, user_id, msg_category, msg_count)
                VALUES (sender_acc, user, msg_category, msg_count);
                
                SET sender_num = sender_num + 1;
                SET dm_count = dm_count - 1;
            END WHILE;
            
            -- Populate General DMs (up to 30 per user)
            SET dm_count = FLOOR(RAND() * 31);  -- Random count between 0 and 30
            SET msg_category = 'General';
            
            WHILE dm_count > 0 DO
                SET sender_acc = CONCAT('Sender_', sender_num);
                SET msg_count = FLOOR(RAND() * 101);  -- Random message count between 0 and 100
                
                INSERT INTO DM (sender_acc, user_id, msg_category, msg_count)
                VALUES (sender_acc, user, msg_category, msg_count);
                
                SET sender_num = sender_num + 1;
                SET dm_count = dm_count - 1;
            END WHILE;
            
            -- Populate Requests DMs (up to 50 per user)
            SET dm_count = FLOOR(RAND() * 51);  -- Random count between 0 and 50
            SET msg_category = 'Requests';
            
            WHILE dm_count > 0 DO
                SET sender_acc = CONCAT('Sender_', sender_num);
                SET msg_count = FLOOR(RAND() * 101);  -- Random message count between 0 and 100
                
                INSERT INTO DM (sender_acc, user_id, msg_category, msg_count)
                VALUES (sender_acc, user, msg_category, msg_count);
                
                SET sender_num = sender_num + 1;
                SET dm_count = dm_count - 1;
            END WHILE;
            
            SET user = user + 1;
        END WHILE;
    END 

    DELIMITER ;

    CALL PopulateDMs();


    -- #6 Populate Bio

    DELIMITER 

    CREATE PROCEDURE PopulateBios()
    BEGIN
        DECLARE user INT DEFAULT 1;
        DECLARE page_category VARCHAR(20);
        DECLARE description VARCHAR(150);

        WHILE user <= 50 DO
            -- Randomly assign a page category for each user
            SET page_category = CASE FLOOR(RAND() * 5)
                WHEN 0 THEN 'Retail'
                WHEN 1 THEN 'Business'
                WHEN 2 THEN 'Digital Creator'
                WHEN 3 THEN 'Edutainment'
                WHEN 4 THEN 'Sports'
            END;

            -- Assign a description based on the page category
            SET description = CASE page_category
                WHEN 'Retail' THEN 'Discover the latest trends and top products for every season!'
                WHEN 'Business' THEN 'Empowering growth with insights, tips, and success stories.'
                WHEN 'Digital Creator' THEN 'Creating content that inspires, educates, and entertains!'
                WHEN 'Edutainment' THEN 'Where learning meets fun – explore, learn, and enjoy.'
                WHEN 'Sports' THEN 'All things sports: news, updates, and fitness motivation.'
            END;

            -- Insert the bio entry for the user
            INSERT INTO Bio (user_id, description, page_category)
            VALUES (user, description, page_category);

            SET user = user + 1;
        END WHILE;
    END 

    DELIMITER ;

    -- Run the procedure to populate Bios
    CALL PopulateBios();

    -- #7 Populate Post_Interactions

    DELIMITER 

    CREATE PROCEDURE PopulatePostInteractions()
    BEGIN
        DECLARE i INT DEFAULT 1;
        DECLARE max_post_id INT DEFAULT 3461;

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
    END 

    DELIMITER ;


    CALL PopulatePostInteractions();

    -- #8 Populate Story_Interactions

    DELIMITER 

    CREATE PROCEDURE PopulateStoryInteractions()
    BEGIN
        DECLARE i INT DEFAULT 1;
        DECLARE max_story_id INT DEFAULT 201;
        DECLARE random_day ENUM('Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat');

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
    END 

    DELIMITER ;

    CALL PopulateStoryInteractions();

    -- # Last step: cross checking 

    -- View all users
    SELECT * FROM User;

    -- View all posts
    SELECT * FROM Post;

    -- View all stories
    SELECT * FROM Story;

    -- View all followers
    SELECT * FROM Follower;

    -- View all direct messages
    SELECT * FROM DM;

    -- View all bios
    SELECT * FROM Bio;

    -- View all post interactions
    SELECT * FROM Post_Interactions;

    -- View all story interactions
    SELECT * FROM Story_Interactions;

alter table user add column password varchar(225);
show tables;

desc user;

desc hashtags;