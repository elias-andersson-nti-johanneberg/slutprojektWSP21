require 'sinatra'
require 'slim'
require 'byebug'
require 'bcrypt'
require 'sqlite3'
enable :sessions

#Funktions program: har alla funktioner samt sköter all kommuniktaion med databasen.

module Model

# Attemts to connect to a given database and gives the results in hashes
#
    def connect_to_db(database_name)
        @db = SQLite3::Database.new(database_name.to_s)
        @db.results_as_hash = true
    end

# Attemts to change the sessions error message
#
# @see connect_to_db
#
# @return [string] the error message
    def set_error(string)
        session[:error] = string
        return session[:error]
    end

# Attemts to take a double array with hashes with it and take out a single element and put them in an array
#
# @return [array] an array with only the selected data
    def selection_from_hash_array(double_array_with_hash, selection)
        new_array = []
        double_array_with_hash.each do |array|
            new_array << array[selection]
        end
        return new_array
    end

    # Attempts to create a new user
    #
    # @param [Hash] params form data
    # @option params [String] username, The username
    # @option params [String] password, The password
    # @option params [String] password_confirm, The repeated password
    #
    # @see Model#create_lvl_relationship
    # @see connect_to_db
    #
    # @return [redirect]
    #   * :'/error' whether an error occured
    #   * :'/' the home page if the user was created 
    def register_new_user()
        username = params[:username]
        password = params[:password]
        password_confirm = params[:password_confirm]
        p username 

        if username.length > 25
            set_error("för långt användarnamn")
            session[:error_register] = true
            return redirect('/register') 
        end

        if username == ""
            set_error("Du skrev inget användarnamn")
            session[:error_register] = true
            return redirect('/register')
        end

        connect_to_db('db\parkour_journey_21_db.db')
        @db.results_as_hash = false
        result = @db.execute("SELECT id FROM users WHERE username = ?", username)

        if result.empty?
            if password == password_confirm
                password_digest = BCrypt::Password.create(password)
                @db.execute("INSERT INTO users (username, pwdigest, rights) VALUES (?,?,?)",username,password_digest, 0)
                @db.results_as_hash = true
                user_id = @db.execute("SELECT id FROM users Where username = ?", username)
                user_id = user_id[0]["id"]
                create_lvl_relationship(user_id)
                return redirect('/')
            else
                #felhantering skapa en hash och slim fil error och ha en funktion som tar emot text meddelandet. 
                set_error("Lösenordet matchade inte")
                session[:error_register] = true
                return redirect('/register')
            end
        else
            set_error("Det användarnamnet har redan blivit tagen")
            session[:error_register] = true
            return redirect('/register')
        end
    end

    # Attempts to login and update session
    #
    # @param [Hash] params form data
    # @option params [String] username The username
    # @option params [String] password The password
    # @result [Hash] params db with users
    # @option params [String] pwdigest, The incrypted password
    # @option params [String] id, The user id
    # @see connect_to_db
    #
    # @return [redirect]
    #   * :'/error' whether an error occured
    #   * :'/user' redirects to the user that logged in
    def login()
        username = params[:username]
        password = params[:password] 
        session[:lastlogin] = Time.now
        if username == ""
            set_error("skrev inget användarnamn")
            session[:error_login] = true
            return redirect('/login')
        end
    
        connect_to_db('db\parkour_journey_21_db.db')
        result = @db.execute("SELECT * FROM users WHERE username=?", username).first
        pwdigest = result["pwdigest"]
        id = result["id"]
        rights = result["rights"]
        if BCrypt::Password.new(pwdigest) == password
            session[:id] = id
            session[:username]= username
            session[:rights] = rights
            return redirect('/user')
        else
            set_error("fel lösenord")
            session[:error_login] = true
            return redirect('/login')
        end
    end

    # Attempts to create a relation table beetween lvls and users
    #
    # @see connect_to_db
    #
    # @return [Nil] just excecutes the commands
    def create_lvl_relationship(user_id)
        connect_to_db('db\parkour_journey_21_db.db')
        @db.execute("INSERT INTO users_lvl_relationship (user_id, lvl_id, progress) VALUES (?, 1, 0)",user_id)
    end

    # Attempts to get the lvl of the session user
    #
    # @see connect_to_db
    #
    # @return [String] The name of the lvl
    def get_lvl(id)
        connect_to_db('db\parkour_journey_21_db.db')
        lvl_id_hash = @db.execute("SELECT DISTINCT lvl_id FROM users_lvl_relationship Where user_id = ?", id) 
        lvl_id = lvl_id_hash[0]["lvl_id"]
        result = @db.execute("SELECT DISTINCT lvlname FROM lvl Where id = ?", lvl_id) 
        return result[0]["lvlname"]
    end

    # Attempts to get the lvl id of the lvl name
    #
    # @see connect_to_db
    #
    # @return [Integer] The id of the lvl
    def get_lvl_id(lvl_name)
        connect_to_db('db\parkour_journey_21_db.db')
        result = @db.execute("SELECT DISTINCT id FROM lvl Where lvlname = ?", lvl_name) 
        lvl_id = result[0]["id"]
        return lvl_id
    end

    # Attempts to get the user id with help of the username
    #
    # @see connect_to_db
    #
    # @return [Integer] The id of the user
    def get_user_id(username)
        connect_to_db('db\parkour_journey_21_db.db')
        result = @db.execute("SELECT DISTINCT id FROM users Where username = ?", username) 
        user_id = result[0]["id"]
        p user_id
        return user_id
    end

    # Attempts to get the list of all the users in the database
    #
    # @see connect_to_db
    #
    # @return [array] List of the usernames
    def get_user_list()
        connect_to_db('db\parkour_journey_21_db.db')
        user_list = @db.execute("SELECT username FROM users")
        p user_list
        return user_list
    end

    # Attempts add a row in the learning table to indicate that a user is learning a move
    #
    # @see connect_to_db
    # 
    # @return [Boolean] True, if it succesfully completes the function
    def learn_move(move_name, username)
        connect_to_db('db\parkour_journey_21_db.db')
        move_id_hash = @db.execute("SELECT id FROM moves WHERE move_name = ?", move_name) 
        move_id = move_id_hash[0]["id"]
        user_id_hash = @db.execute("SELECT id FROM users WHERE username = ?", username) 
        user_id = user_id_hash[0]["id"]
        @db.execute("Insert INTO learning (user_id, move_id) VALUES (?,?)", user_id, move_id)
        return true
    end

    # Attempts add a row in the learned table to indicate that a user have learned a move
    #
    # @see connect_to_db
    #
    # @return [Boolean] True, if it succesfully completes the function
    def learned_move(move_name, username)
        connect_to_db('db\parkour_journey_21_db.db')
        move_id_hash = @db.execute("SELECT id FROM moves WHERE move_name = ?", move_name) 
        move_id = move_id_hash[0]["id"]
        user_id_hash = @db.execute("SELECT id FROM users WHERE username = ?", username) 
        user_id = user_id_hash[0]["id"]
        @db.execute("Insert INTO learned (user_id, move_id) VALUES (?,?)", user_id, move_id)
        @db.execute("DELETE FROM learning WHERE move_id = ?", move_id)
        return true
    end

    # Checks if the user have learned or is learning a specific move
    #
    # @see connect_to_db
    #
    # @return [Boolean] True, if the user is learning or have learnt the move 
    # @return [Boolean] False, if the user had not learnt or is learning the move
    def check_user_learned_list(user_learned_list,user_learning_list, move_n)
        user_learned_list.each do  |move|
            if move["move_name"] == move_n
                return true
            end
        end
        user_learning_list.each do  |move|
            if move["move_name"] == move_n
                return true
            end
        end
        return false
    end

    # Attempts to get all the data on the moves in a specific lvl
    #
    # @see get_lvl
    # @see get_lvl_id
    # @see connect_to_db
    #
    # @return [Hash] 
    #   * :id [Integer] The ID of the move
    #   * :move_name [String] The name of the move
    #   * :content [String] The content of the article
    #   * :difficulty [Integer] The number meaning how hard the move is
    #   * :created_user_id [Integer] The user id of the user that created the move
     #  * :img_path [String] The path to the corresponding image
    def get_moves(username,id)
        connect_to_db('db\parkour_journey_21_db.db')
        if username == "admin"
            result = @db.execute("SELECT * FROM moves") 
        else
        user_lvl = get_lvl(id)
        user_difficulty = get_lvl_id(user_lvl)
        result = @db.execute("SELECT * FROM moves Where difficulty = ?", user_difficulty) 
        end
        return result
    end

    # Attempts to get all the names of the moves with the help of their id and put them in an array
    #
    # @see connect_to_db
    # 
    # @return [Array] of all the moves names
    def select_moves_with_id(array_of_moves_id)
        connect_to_db('db\parkour_journey_21_db.db')
        array_of_moves_name = []
        array_of_moves_id.each do |id|
            move_name = @db.execute("SELECT * FROM moves WHERE id = ?", id)
            array_of_moves_name << move_name[0]
        end
        return array_of_moves_name
    end

    # Attempts to get all the names of the moves that a user is learning
    #
    # @see selection_from_hash_array
    # @see select_moves_with:id
    # @see connect_to_db
    #
    # @return [Array] An array with names of moves that the user is learning
    def get_learning_moves(username)
        connect_to_db('db\parkour_journey_21_db.db')
        user_id_hash = @db.execute("SELECT id FROM users WHERE username = ?", username) 
        user_id = user_id_hash[0]["id"]
        result = @db.execute("SELECT move_id FROM learning Where user_id = ?", user_id) 
        move_names = selection_from_hash_array(result, "move_id")
        learning_moves_list = select_moves_with_id(move_names)
        return learning_moves_list
    end

    # Attempts to get all the names of the moves that a user have learnt
    #
    # @see selection_from_hash_array
    # @see select_moves_with:id
    # @see connect_to_db
    #
    # @return [Array] An array with names of moves that the user have learnt
    def get_learned_moves(username)
        connect_to_db('db\parkour_journey_21_db.db')
        user_id_hash = @db.execute("SELECT id FROM users WHERE username = ?", username) 
        user_id = user_id_hash[0]["id"]
        result = @db.execute("SELECT move_id FROM learned Where user_id = ?", user_id) 
        move_names = selection_from_hash_array(result, "move_id")
        learned_moves_list = select_moves_with_id(move_names)
    
        return learned_moves_list
    end

    # Attempts to create a new move and thus creates a new row in the move table
    #
    # @see selection_from_hash_array
    # @see select_moves_with:id
    #
    # @return [Boolean] True, if the functions works perfectly and changes the database
    def new_move(move_name, move_content, difficulty, genre, img_path)
        created_by = 0
        connect_to_db('db\parkour_journey_21_db.db') 
        @db.results_as_hash = false
        @db.execute("INSERT INTO moves (move_name, content, difficulty, created_user_id, img_path) VALUES (?,?,?,?,?)",move_name, move_content, difficulty, created_by, img_path)
        move_id = @db.execute("SELECT id FROM moves WHERE move_name = ?", move_name) 
        @db.execute("Insert INTO genre_move_relationship (genre_id, move_id) VALUES (?,?)", genre, move_id)
        return true
    end 

    # Checks the lvl of the session user and changes it if the user is worthy of leveling up
    #
    # @see change_lvl
    #
    # @return [Nil] Just executes the commands in the funtion
    def check_lvl(username, user_learned_list,id)
        user_lvl = get_lvl(id)
        if user_learned_list.count == 4 && user_lvl == "Noob"
            change_lvl("Beginner",username)
        elsif user_learned_list.count == 15 && user_lvl == "Beginner"
            change_lvl("Intermediete",username)
        elsif user_learned_list.count == 20 && user_lvl == "Intermediate"
            change_lvl("Athlete",username)
        elsif user_learned_list.count == 25 && user_lvl == "Athlete"
            change_lvl("Legend",username)
        end
    end

    # Attempts to delete a user
    #
    # @see connect_to_db
    # @see get_user_id
    #
    # @return [Nil] Just executes the commands in the funtion
    def delete_username(username)
        connect_to_db('db\parkour_journey_21_db.db')
        user_id = get_user_id(username)
        @db.execute("DELETE from users_lvl_relationship Where user_id = ?", user_id)
        @db.execute("DELETE from learning Where user_id = ?", user_id)
        @db.execute("DELETE from learned WHERE user_id = ?", user_id)
        @db.execute("DELETE from users Where id = ?", user_id)
    end

    # Attempts to change the username of a user
    #
    # @see connect_to_db
    # @see set_error
    # @see get_user_list
    # @see get_user_id
    #
    # @return [Nil] Just executes the commands in the funtion
    def change_username(old_username,new_username)
        connect_to_db('db\parkour_journey_21_db.db')
        user_list = get_user_list()
        check = false
        check2 = false
        
        if old_username == "" || new_username == ""
            session[:username_error] = true
            set_error("Du får inte lämna blankt")
            return redirect('/user/edit')
        end

        user_list.each do |user|
            if old_username == user["username"]
                check = true
                break
            end
        end
        if check == false
            session[:username_error] = true
            set_error("Det finns inget gammalt användarnamn vid det namnet")
            return redirect('/user/edit')
        end

        user_list.each do |user|
            if new_username == user["username"]
                check2 = true
                break
            end
        end
        if check2 == true
            session[:username_error] = true
            set_error("Det användarnamnet är redan taget")
            return redirect('/user/edit')
        end

        user_id = get_user_id(old_username)
        @db.execute("UPDATE users SET username = ? WHERE id = ?",new_username, user_id)
    end

    # Attempts to change the lvl of a specific user 
    #
    # @see get_lvl_id
    # @see get_user_id
    #
    # @return [command] Updates the relation table beteween users and lvls
    def change_lvl(new_lvl, username)
        connect_to_db('db\parkour_journey_21_db.db')
        @db.results_as_hash = false
        lvl_id = get_lvl_id(new_lvl)
        user_id = get_user_id(username)
        @db.execute("DELETE from users_lvl_relationship Where user_id = ?", user_id)
        return @db.execute("insert into users_lvl_relationship (user_id, lvl_id, progress) VALUES (?, ?, 0)", user_id, lvl_id)
    end
end

