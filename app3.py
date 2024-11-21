import streamlit as st
import mysql.connector
from mysql.connector import Error
from datetime import date
def create_connection():
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='Ankit@2003',
            database='user_insights'
        )
        if connection.is_connected():
            return connection
    except Error as e:
        st.error(f"Error: {e}")
        return None
    
#This function will validate the user by checking the password format which they are entering
def validate_user(user_id, password):
    expected_password = f"password{user_id}"
    if password == expected_password:
        return True
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("SELECT password FROM User WHERE user_id = %s", (user_id,))
        result = cursor.fetchone()
        connection.close()
        return result is not None and result[0] == password
    return False

#This function will generate the next user id while new user is registering
def get_next_user_id():
    db = create_connection()
    cursor = db.cursor()
    cursor.execute("SELECT MAX(user_id) FROM user")
    max_user_id = cursor.fetchone()[0]
    next_user_id = max_user_id + 1 if max_user_id else 51
    cursor.close()
    db.close()
    return next_user_id

#This function is to create a registration page for new users
def register_user(fname, lname, dob, acc_type):
    new_user_id = get_next_user_id()
    user_password = f"password{new_user_id}"
    db = create_connection()
    cursor = db.cursor()
    cursor.execute("CALL AddNewUser(%s, %s, %s, %s)", (fname, lname, dob, acc_type))
    db.commit()
    cursor.close()
    db.close()
    return new_user_id, user_password

#This function gets the trending hashtags presently in the social media
def get_trending_hashtags():
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.callproc('GetTopHashtags')
            hashtags = []
            for result in cursor.stored_results():
                hashtags.extend([row[0] for row in result.fetchall()])
            top_hashtags = hashtags[:5]
            display_hashtags(top_hashtags)
        except Error as e:
            st.error(f"Error fetching hashtags: {e}")
        finally:
            connection.close()

#This function displays the hashtags on the frontpage
def display_hashtags(hashtags):
    st.markdown("<style>" +
                """
                .hashtag-panel {
                    background-color: #f9f9f9;
                    border-radius: 10px;
                    padding: 15px;
                    margin: 10px 0;
                    text-align: center;
                    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
                    font-weight: bold;
                }
                .hashtag-panel h3 {
                    color: #333;
                    font-size: 1.2em;
                    margin: 0;
                }
                """ +
                "</style>", unsafe_allow_html=True)
    for i, hashtag in enumerate(hashtags, start=1):
        st.markdown(f"<div class='hashtag-panel'><h3>{i}. {hashtag}</h3></div>", unsafe_allow_html=True)

#This function is to get the trending locations
def get_trending_location():
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.callproc('GetTopLocations')
            locations = []
            for result in cursor.stored_results():
                locations.extend([row[0] for row in result.fetchall()])
            top_locations = locations[:5]
            display_location(top_locations)
        except Error as e:
            st.error(f"Error fetching locations: {e}")
        finally:
            connection.close()

#This function is to display those trending location on the front page
def display_location(locations):
    st.markdown("<style>" +
                """
                .location-panel {
                    background-color: #f9f9f9;
                    border-radius: 10px;
                    padding: 15px;
                    margin: 10px 0;
                    text-align: center;
                    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
                    font-weight: bold;
                }
                .location-panel h3 {
                    color: #333;
                    font-size: 1.2em;
                    margin: 0;
                }
                """ +
                "</style>", unsafe_allow_html=True)
    for i, locations in enumerate(locations, start=1):
        st.markdown(f"<div class='location-panel'><h3>{i}. {locations}</h3></div>", unsafe_allow_html=True)

#This function is to get the hashtag metrics of a specific hashtag
def get_hashtag_metrics(user_id, hashtag):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.callproc('GetHashtagMetrics', (user_id, hashtag))
            result = None
            for result in cursor.stored_results():
                metrics = result.fetchone()            
            if metrics:
                hashtag_perc=((metrics[2]/metrics[3])/(metrics[0]/metrics[1]))*100;
                return hashtag_perc
            else:
                st.error("No data available for the specified hashtag and user.")
                return {}
        except Error as e:
            st.error(f"Error fetching hashtag metrics: {e}")
            return {}
        finally:
            connection.close()

#This function to display the metrics of the hashtag 
def hashtag_productivity():
    st.write("## Hashtag Productivity")
    user_id = st.session_state.get('user_id')
    if not user_id:
        st.error("You must be logged in to access hashtag productivity metrics.")
        return
    hashtag = st.text_input("Enter Hashtag (e.g., #summer)")
    if st.button("Get Hashtag Metrics"):
        if hashtag:
            metrics = get_hashtag_metrics(user_id, hashtag)
            st.write(f"Productivity: {metrics:.2f}%")
        else:
            st.error("Please provide a hashtag.")

#This function is to get the story metrics of the user
def get_story_metrics(user_id):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.execute(f"CALL GetUserStoryMetrics({user_id})")
            daily_reach = cursor.fetchall()
            day_reach_data = daily_reach if daily_reach else []
            day_total_reach = sum(reach for _, reach in day_reach_data)
            cursor.nextset()
            time_interval_reach = cursor.fetchall()
            time_reach_data = time_interval_reach if time_interval_reach else []
            time_total_reach = sum(reach for _, reach in time_reach_data)
            cursor.nextset()
            story_metrics = cursor.fetchone()
            if story_metrics:
                total_story_reach = story_metrics[0]
                st.subheader("Total Story Metrics")
                st.write(f"Story Reach: {total_story_reach}")
                st.write(f"Story Interactions: {story_metrics[1]}")
            else:
                st.error("No overall story metrics found.")
                return
            if day_reach_data:
                st.subheader("Story Reach by Day")
                for day, reach in day_reach_data:
                    percentage = (reach / day_total_reach) * 100 if day_total_reach else 0
                    st.write(f"{day}: {percentage:.2f}%")
            else:
                st.error("No day-wise reach data found.")
            if time_reach_data:
                st.subheader("Story Reach by Time Interval")
                for interval, reach in time_reach_data:
                    percentage = (reach / time_total_reach) * 100 if time_total_reach else 0
                    st.write(f"{interval}: {percentage:.2f}%")
            else:
                st.error("No time interval reach data found.")
        except Error as e:
            st.error(f"Error fetching story metrics: {e}")
        finally:
            connection.close()

#This function is to display the story metrics
def story_insights():
    st.write("## Story Insights")
    user_id = st.session_state.get('user_id')
    if not user_id:
        st.error("You must be logged in to access Story metrics.")
        return
    if st.button("Get Story Metrics"):
        metrics = get_story_metrics(user_id)
        if metrics:
            st.write("### Story Insights")
            for key, value in metrics.items():
                st.write(f"{key}: {value}")

#This function is to get the post metrics of the user
def get_post_metrics(user_id):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.execute(f"CALL GetUserPostMetrics({user_id})")
            total_metrics = cursor.fetchone()
            if total_metrics:
                total_reach = total_metrics[0]
                st.subheader("Total Metrics")
                st.write(f"Total Reach: {total_reach}")
                st.write(f"Post Interactions: {total_metrics[1]}")
            else:
                st.error("No total metrics found.")
                return
            cursor.nextset()
            location_metrics = cursor.fetchall()
            if location_metrics:
                st.subheader("Post Reach by Location")
                for location, reach in location_metrics:
                    reach_percentage = (reach / total_reach) * 100
                    st.write(f"{location}: {reach_percentage:.2f}%")
            else:
                st.error("No location metrics found.")
            cursor.nextset()
            other_location = cursor.fetchone()
            if other_location:
                reach_percentage = (other_location[1] / total_reach) * 100
                st.write(f"Other Locations: {reach_percentage:.2f}%")
            else:
                st.error("No 'Other' location data found.")
            cursor.nextset()
            type_metrics = cursor.fetchall()
            if type_metrics:
                st.subheader("Post Reach by Type")
                for post_type, reach in type_metrics:
                    reach_percentage = (reach / total_reach) * 100
                    st.write(f"{post_type}: {reach_percentage:.2f}%")
            else:
                st.error("No type metrics found.")

        except Error as e:
            st.error(f"Error fetching post metrics: {e}")
        finally:
            connection.close()

#This function is to display the post metrics of the user
def post_insights():
    st.write("## Post Insights")
    user_id = st.session_state.get('user_id')
    if not user_id:
        st.error("You must be logged in to access post metrics.")
        return
    if st.button("Get Post Metrics"):
        get_post_metrics(user_id)


def get_follower_stats(user_id):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.execute(f"CALL GetFollowerStats({user_id})")
            st.subheader("Top Cities by Follower Count")
            city_data = cursor.fetchall()
            if city_data:
                for city, count in city_data:
                    st.write(f"{city}: {count} followers")
            else:
                st.error("No city data found.")
            cursor.nextset()
            st.subheader("Followers by Gender")
            gender_data = cursor.fetchall()
            if gender_data:
                for gender, count in gender_data:
                    st.write(f"{gender}: {count} followers")
            else:
                st.error("No gender data found.")
            cursor.nextset()
            st.subheader("Followers by Age Range")
            age_data = cursor.fetchall()
            if age_data:
                for age_range, count in age_data:
                    st.write(f"{age_range}: {count} followers")
            else:
                st.error("No age range data found.")
        except Error as e:
            st.error(f"Error fetching follower stats: {e}")
        finally:
            connection.close()
        
#This function is to get the follower analysis of the user
def follower_analysis():
    st.write("## Follower Analysis")
    user_id = st.session_state.get('user_id')
    if not user_id:
        st.error("You must be logged in to access Follower Analysis.")
        return
    if st.button("Get Follower Stats"):
        get_follower_stats(user_id)

#This function is to get the DMs of the user
def get_user_dms(user_id):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.execute(f"CALL GetUserDMs({user_id})")
            st.subheader("Total Number of DMs")
            total_dms = cursor.fetchone()
            if total_dms:
                st.write(f"Total DMs: {total_dms[0]}")
            else:
                st.error("No DM data found.")
            cursor.nextset()
            st.subheader("DMs by Category")
            category_data = cursor.fetchall()
            if category_data:
                for category, count in category_data:
                    st.write(f"{category}: {count} DMs")
            else:
                st.error("No category data found.")
        except Error as e:
            st.error(f"Error fetching DM stats: {e}")
        finally:
            connection.close()
        
#This function displays the type of DMs the user has received
def dm_analysis():
    st.write("## Direct Message (DM) Analysis")
    user_id = st.session_state.get('user_id')
    if not user_id:
        st.error("You must be logged in to access DM Analysis.")
        return
    if st.button("Get DM Stats"):
        get_user_dms(user_id)

#This function is to provide the metrics as to which day and which hour the post will be productive 
def get_total_reach_grouped(user_id):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.execute(f"CALL GetTotalReachGrouped({user_id})")
            st.subheader("Total Reach by Day")
            day_reach = cursor.fetchall()
            if day_reach:
                for day, total_reach in day_reach:
                    st.write(f"{day}: {total_reach} views")
            else:
                st.error("No reach data found for days.")
            cursor.nextset()
            st.subheader("Total Reach by 3-Hour Time Intervals")
            time_interval_reach = cursor.fetchall()
            if time_interval_reach:
                for interval, total_reach in time_interval_reach:
                    st.write(f"{interval}: {total_reach} views")
            else:
                st.error("No reach data found for time intervals.")
        except Error as e:
            st.error(f"Error fetching reach data: {e}")
        finally:
            connection.close()

#This display the above metrics 
def reach_insights():
    st.write("## Reach Insights")
    user_id = st.session_state.get('user_id')
    if not user_id:
        st.error("You must be logged in to access Reach Insights.")
        return
    if st.button("Get Total Reach Grouped"):
        get_total_reach_grouped(user_id)

#This function is to delete the account of the user
def delete_account():
    user_id = st.session_state.get('user_id')
    if user_id:
        connection = create_connection()
        if connection:
            cursor = connection.cursor()
            try:
                cursor.execute(f"CALL DeleteUser({user_id})")
                connection.commit()
                st.success("Your account has been deleted.")
                st.session_state.clear()
                st.rerun()
            except Error as e:
                st.error(f"Error deleting account: {e}")
                connection.rollback()
            finally:
                connection.close()
    else:
        st.error("No user is logged in to delete.")

#This function is to build the login page of our website
def login_page():
    st.title("Login")
    user_id = st.text_input("User ID", key="user_id_input")
    password = st.text_input("Password", type="password", key="password_input")
    if st.button("Submit"):
        if validate_user(user_id, password):
            st.session_state['logged_in'] = True
            st.session_state['user_id'] = user_id
            st.session_state['page'] = 'dashboard'
            st.success("Login successful!")
            st.rerun()
        else:
            st.error("Invalid User ID or Password. Use 'password{user_id}' format for the password.")
    if st.button("Register"):
        st.session_state['page'] = 'register'
        st.rerun()

#This function gets the list of users already present in our database
def get_all_users():
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("SELECT user_id, fname, lname FROM User;")
        users = cursor.fetchall()
        connection.close()
        return users
    return []

#This function is to build the registration page's logic 
def registration_page():
    if 'registration_success' not in st.session_state:
        st.session_state['registration_success'] = False
    if 'new_user_id' not in st.session_state:
        st.session_state['new_user_id'] = None
    if 'user_password' not in st.session_state:
        st.session_state['user_password'] = None
    st.title("Register")
    fname = st.text_input("First Name")
    lname = st.text_input("Last Name")
    dob = st.date_input("Date of Birth", min_value=date(1950, 1, 1), max_value=date.today())
    acc_type = st.selectbox("Account Type", ["Creator", "Business"])
    if st.button("Register"):
        if fname and lname and acc_type:
            try:
                new_user_id, user_password = register_user(fname, lname, dob, acc_type)
                st.session_state['registration_success'] = True
                st.session_state['new_user_id'] = new_user_id
                st.session_state['user_password'] = user_password
            except Exception as e:
                st.session_state['registration_success'] = False
                st.error(f"Registration failed: {str(e)}")
        else:
            st.error("Please complete all fields.")
    if st.session_state['registration_success']:
        st.success(f"Account created! Your User ID is {st.session_state['new_user_id']} and password is {st.session_state['user_password']}")
        if st.button("Return Back"):
                st.session_state['page'] = 'login'

#This function will get the information of the user who is logging in to our website                
def get_user_info(user_id):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.execute(f"CALL GetUserInfo({user_id})")
            user_info = cursor.fetchone()
            if user_info and len(user_info) == 4:
                fname, lname, _, page_category = user_info 
                return fname, lname, page_category
            else:
                return None, None, None
        except Error as e:
            st.error(f"Error fetching user info: {e}")
            return None, None, None
        finally:
            connection.close()
    return None, None, None

#This function fetches the follower count of the user and displays it on the dashboard
def follower_count(user_id):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.execute(f"SELECT GetFollowerCount({user_id})")
            user_info = cursor.fetchone()
            if user_info and len(user_info) == 1:
                followercount = user_info[0] 
                return followercount
            else:
                st.error("Follower count not found or has unexpected format.")
                return None
        except Error as e:
            st.error(f"Error fetching follower count: {e}")
            return None
        finally:
            connection.close()

def get_all_users():
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("SELECT user_id, fname, lname FROM User;")
        users = cursor.fetchall()
        connection.close()
        return users
    return []

def delete_user_by_admin(user_id):
    connection = create_connection()
    if connection:
        cursor = connection.cursor()
        try:
            cursor.execute(f"CALL DeleteUser({user_id});")
            connection.commit()
            st.success("User account deleted successfully.")
        except Error as e:
            st.error(f"Error deleting user account: {e}")
            connection.rollback()
        finally:
            connection.close()

# Admin page layout
def admin_page():
    st.title("Admin Dashboard")

    # Display users list
    st.header("User Accounts")
    users = get_all_users()
    if users:
        user_selection = st.selectbox("Select a user to delete:", options=[f"{u[1]} {u[2]} (ID: {u[0]})" for u in users])
        if user_selection:
            selected_user_id = int(user_selection.split("ID: ")[1][:-1])

            # Delete button for admin
            if st.button("Delete Selected User Account"):
                delete_user_by_admin(selected_user_id)
    else:
        st.info("No users found.")

# Main application
if 'is_admin' not in st.session_state:
    st.session_state['is_admin'] = False

# Admin login
if st.session_state['is_admin']:
    admin_page()
else:
    st.title("Admin Login")
    username = st.text_input("Username")
    password = st.text_input("Password", type="password")

    if st.button("Login as Admin"):
        if username == 'admin_user' and password == 'AnkitArjunagi@2003':
            st.session_state['is_admin'] = True
            st.rerun()
        else:
            st.error("Invalid credentials.")

#This function is to build the dashboard of the user 
def dashboard():
    st.title("Social Media Insights")
    user_id = st.session_state.get('user_id') 
    if user_id:
        fname, lname, page_category = get_user_info(user_id)
        if fname and lname and page_category:
            st.title(f"Welcome {fname} {lname}")
            st.subheader(f"Page Category: {page_category}")
        else:
            st.error("User information not found or has an unexpected format.")
    followercount = follower_count(user_id)
    if followercount is not None:
        st.subheader(f"Followers: {followercount}")
    else:
        st.error("Failed to fetch follower count.")
    st.subheader("Trending Now")
    st.write("### Hashtags")
    hashtags = get_trending_hashtags()
    if hashtags:
        for i, hashtag in enumerate(hashtags, 1):
            st.write(f"{i}. {hashtag}")
    st.write("### Locations")
    locations = get_trending_location()
    if locations:
        for i, location in enumerate(locations, 1):
            st.write(f"{i}. {location}")
    if st.button("Delete Account"):
        delete_account()

#This function is to build the navigation bar 
def sidebar():
    st.sidebar.header("Navigation")
    page = st.sidebar.radio("Go to", 
        ("🏠 Dashboard", 
         "📊 Follower Analysis", 
         "🌍 Reach", 
         "🏷️ Hashtag Productivity", 
         "📈 Post Insights",
         "📖 Story Insights",
         "💬 DM Analysis",
        )
    )
    if page == "🏠 Dashboard":
        dashboard()
    elif page == "📊 Follower Analysis":
        follower_analysis()
    elif page == "🌍 Reach":
        reach_insights()
    elif page == "🏷️ Hashtag Productivity":
        hashtag_productivity()
    elif page == "📈 Post Insights":
        post_insights()
    elif page == "📖 Story Insights":
        story_insights()
    elif page == "💬 DM Analysis":
        dm_analysis()
    if st.sidebar.button("🚪 Logout"):
        st.session_state['logged_in'] = False
        st.session_state['page'] = 'login'
        st.success("You have been logged out.")
        st.rerun()
if 'logged_in' not in st.session_state:
    st.session_state['logged_in'] = False
if 'page' not in st.session_state:
    st.session_state['page'] = 'login'
if st.session_state['logged_in']:
    sidebar()
else:
    if st.session_state['page'] == 'login':
        login_page()
    elif st.session_state['page'] == 'register':
        registration_page()