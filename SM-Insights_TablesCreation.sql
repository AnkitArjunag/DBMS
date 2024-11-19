CREATE TABLE User(
	user_id INT PRIMARY KEY,
    fname VARCHAR(20),
    lname VARCHAR(20),
    DOB DATE,
    acc_type ENUM('Creator','Business')
) ;

-- DROP TABLE User;

CREATE TABLE Post(
	post_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    post_views INT,
    post_likes INT,
    post_shares INT,
    post_comments INT,
    post_saves INT,
    post_type ENUM('Post','Reel'),
    post_location VARCHAR(50),
    hashtags VARCHAR(400),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- DROP TABLE Post;

CREATE TABLE Story(
	story_id INT,
    user_id INT,
    story_views INT,
    story_likes INT,
    no_of_replies INT,
    PRIMARY KEY(story_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- DROP TABLE Story;

CREATE TABLE Follower(
	flr_username VARCHAR(25) PRIMARY KEY,
    user_id INT,
    city VARCHAR(20),
    country VARCHAR(20),
    gender ENUM('Male','Female'),
    age INT,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- DROP TABLE Follower;

CREATE TABLE DM(
	sender_acc VARCHAR(25) PRIMARY KEY,
    user_id INT,
    msg_category ENUM('Primary','General','Requests'),
    msg_count INT,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- DROP TABLE DM;

CREATE TABLE Bio(
	user_id INT,
    description VARCHAR(150),	-- instagram allows a bio of 150 characters
    page_category VARCHAR(20),
    PRIMARY KEY (user_id, description),
    FOREIGN KEY (user_id) references User(user_id)
);

-- DROP TABLE Bio;

CREATE TABLE Post_Interactions(
	post_id INT,
    flr_username VARCHAR(25),
    timestamp timestamp,
    day ENUM('Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat'),
    PRIMARY KEY (post_id,flr_username),
    FOREIGN KEY (post_id) references Post(post_id),
    FOREIGN KEY (flr_username) REFERENCES Follower(flr_username)
);

-- DROP TABLE Post_Interactions;

CREATE TABLE Story_Interactions(
	story_id INT,
    flr_username VARCHAR(25),
    timestamp timestamp,
    day ENUM('Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat'),
    PRIMARY KEY (story_id,flr_username),
    FOREIGN KEY (story_id) references Story(story_id),
    FOREIGN KEY (flr_username) REFERENCES Follower(flr_username)
);

-- DROP TABLE Story_Interactions;



