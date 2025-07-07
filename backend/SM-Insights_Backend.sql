DELIMITER //

CREATE PROCEDURE AddNewUser()
BEGIN
    DECLARE last_user_id INT;
    DECLARE new_user_id INT;
    DECLARE random_dob DATE;
    DECLARE random_acc_type ENUM('Creator', 'Business');

    -- Fetch the last user_id
    SELECT MAX(user_id) INTO last_user_id FROM User;
    SET new_user_id = last_user_id + 1;

    -- Generate random name, DOB, and account type
    SET random_dob = DATE_ADD('1955-01-01', INTERVAL FLOOR(RAND() * 20820) DAY);  -- Random date from 1955 to 2012
    SET random_acc_type = IF(RAND() < 0.67, 'Creator', 'Business');

    -- Insert into User table
    INSERT INTO User (user_id, fname, lname, DOB, acc_type)
    VALUES (new_user_id, CONCAT('John', new_user_id), CONCAT('Doe', new_user_id), random_dob, random_acc_type);

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
--    CALL PopulatePostInteractionsForUser();

    -- Populate Story Interactions for the new user
--    CALL PopulateStoryInteractionsForUser();
END //

DELIMITER ;

-- CALL AddNewUser();

-- DELIMITER //

-- CREATE PROCEDURE DeleteUser(IN delete_user_id INT)
-- BEGIN
--     -- Delete related records from other tables
--     DELETE FROM Post_Interactions WHERE post_id IN (SELECT post_id FROM Post WHERE user_id = delete_user_id);
--     DELETE FROM Story_Interactions WHERE story_id IN (SELECT story_id FROM Story WHERE user_id = delete_user_id);
--     DELETE FROM Post WHERE user_id = delete_user_id;
--     DELETE FROM Story WHERE user_id = delete_user_id;
--     DELETE FROM Follower WHERE user_id = delete_user_id;
--     DELETE FROM DM WHERE user_id = delete_user_id;
--     DELETE FROM Bio WHERE user_id = delete_user_id;

--     -- Delete user record from User table
--     DELETE FROM User WHERE user_id = delete_user_id;
-- END //

-- DELIMITER ;

-- CALL DeleteUser(53);

DELIMITER //

CREATE PROCEDURE DeleteUser(IN delete_user_id INT)
BEGIN
    Delete related records from other tables
    DELETE FROM Post_Interactions WHERE post_id IN (SELECT post_id FROM Post WHERE user_id = delete_user_id);
    DELETE FROM Story_Interactions WHERE story_id IN (SELECT story_id FROM Story WHERE user_id = delete_user_id);
    DELETE FROM Post WHERE user_id = delete_user_id;
    DELETE FROM Story WHERE user_id = delete_user_id;
    DELETE FROM Follower WHERE user_id = delete_user_id;
    DELETE FROM DM WHERE user_id = delete_user_id;
    DELETE FROM Bio WHERE user_id = delete_user_id;

    -- Delete user record from User table
    DELETE FROM User WHERE user_id = delete_user_id;
END //

DELIMITER ;

-- CALL DeleteUser(30);

DROP PROCEDURE IF EXISTS DeleteUser;

select * from user;

CALL DeleteUser(53);

DELIMITER //

CREATE TRIGGER BeforeDeleteUser
BEFORE DELETE ON User
FOR EACH ROW
BEGIN
    -- Delete related records from other tables based on the user_id being deleted
    DELETE FROM Post_Interactions WHERE post_id IN (SELECT post_id FROM Post WHERE user_id = OLD.user_id);
    DELETE FROM Story_Interactions WHERE story_id IN (SELECT story_id FROM Story WHERE user_id = OLD.user_id);
    DELETE FROM Post WHERE user_id = OLD.user_id;
    DELETE FROM Story WHERE user_id = OLD.user_id;
    DELETE FROM Follower WHERE user_id = OLD.user_id;
    DELETE FROM DM WHERE user_id = OLD.user_id;
    DELETE FROM Bio WHERE user_id = OLD.user_id;
END //

DELIMITER ;
