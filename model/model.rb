require 'sinatra'
require 'slim'
require 'byebug'
require 'bcrypt'
require 'sqlite3'
enable :sessions

#Funktions program: har alla funktioner samt sköter all kommuniktaion med databasen.

module Model

# Attemts to make the computer wait before doing the next command
#
# @return [Boolean] True, if the function worked
    def wait(seconds)
        sleep(seconds)
        return true
    end

    def connect_to_db(database_name)
        @db = SQLite3::Database.new(database_name.to_s)
        @db.results_as_hash = true
    end

# Attemts to change the sessions error message
#
# @return [string] the error message
    def set_error(string, error)
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
    #
    # @return [redirect]
    #   * :'/error' whether an error occured
    #   * :'/' the home page if the user was created 
    def register_new_user()
        username = params[:username]
        password = params[:password]
        password_confirm = params[:password_confirm]

        if username == nil
            set_error("Du skrev inget användarnamn")
            return redirect('/error')
        end

        connect_to_db('db\parkour_journey_21_db.db')
        @db.results_as_hash = false
        result = @db.execute("SELECT id FROM users WHERE username = ?", username)


        if result.empty?
            if password == password_confirm
                password_digest = BCrypt::Password.create(password)
                @db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)",username,password_digest)
                @db.results_as_hash = true
                user_id = @db.execute("SELECT id FROM users Where username = ?", username)
                user_id = user_id[0]["id"]
                create_lvl_relationship(user_id)
                return redirect('/')
            else
                #felhantering skapa en hash och slim fil error och ha en funktion som tar emot text meddelandet. 
                set_error("Lösenordet matchade inte")
                return redirect('/error')
            end
        else
            set_error("Det användarnamnet har redan blivit tagen")
            return redirect('/error')
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
    #
    # @return [redirect]
    #   * :'/error' whether an error occured
    #   * :'/user' redirects to the user that logged in
    def login()
        username = params[:username]
        password = params[:password] 
    
        if username == ""
        set_error("skrev inget användarnamn")
        return redirect('/error')
        end
    
        connect_to_db('db\parkour_journey_21_db.db')
        result = @db.execute("SELECT * FROM users WHERE username=?", username).first
        pwdigest = result["pwdigest"]
        id = result["id"]
    
        #FIXA SÅ ATT SESSIONS STÅR I APP
        if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        session[:username]= username
        return redirect('/user')
        else
            set_error("fel lösenord")
            return redirect('/error')
        end
    end

    # Attempts to create a relation table beetween lvls and users
    #
    # @return [Nil] just excecutes the commands
    def create_lvl_relationship(user_id)
        connect_to_db('db\parkour_journey_21_db.db')
        @db.execute("INSERT INTO users_lvl_relationship (user_id, lvl_id, progress) VALUES (?, 1, 0)",user_id)
    end

    # Attempts to get the lvl of the session user
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
    # @return [Integer] The id of the lvl
    def get_lvl_id(lvl_name)
        connect_to_db('db\parkour_journey_21_db.db')
        result = @db.execute("SELECT DISTINCT id FROM lvl Where lvlname = ?", lvl_name) 
        lvl_id = result[0]["id"]
        return lvl_id
    end

    # Attempts to get the user id with help of the username
    #
    # @return [Integer] The id of the user
    def get_user_id(username)
        connect_to_db('db\parkour_journey_21_db.db')
        result = db.execute("SELECT DISTINCT id FROM users Where username = ?", username) 
        user_id = result[0]["id"]
        p user_id
        return user_id
    end

    def get_user_list()
        connect_to_db('db\parkour_journey_21_db.db')
        user_list = @db.execute("SELECT username FROM users")
        p user_list
        return user_list
    end

    # Attempts add a row in the learning table to indicate that a user is learning a move
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
