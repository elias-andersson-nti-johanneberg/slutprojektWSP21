require 'sinatra'
require 'slim'
require 'byebug'
require 'bcrypt'
require 'sqlite3'

enable :sessions


#Funktions program: har alla funktioner samt sköter all kommuniktaion med databasen.

def wait(seconds)
    sleep(seconds)
    return true
end

def set_error(string)
    session[:error] = string
    return session[:error]
end

def register_new_user()
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if username == nil
        set_error("Du skrev inget användarnamn")
        return redirect('/error')
    end

    db = SQLite3::Database.new('db/parkour_journey_21_db.db')
    result = db.execute("SELECT id FROM users WHERE username = ?", username)


    if result.empty?
        if password == password_confirm
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)",username,password_digest)
            db.results_as_hash = true
            user_id = db.execute("SELECT id FROM users Where username = ?", username)
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

def login()
    username = params[:username]
    password = params[:password] 
  
    if username == ""
      set_error("skrev inget användarnamn")
      return redirect('/error')
    end
  
    db = SQLite3::Database.new('db/parkour_journey_21_db.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username=?", username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:username]= username
      return redirect('/user')
    else
        set_error("fel lösenord")
        return redirect('/error')
    end
end

def create_lvl_relationship(user_id)
 db = SQLite3::Database.new('db/parkour_journey_21_db.db')
 db.results_as_hash = true
 db.execute("INSERT INTO users_lvl_relationship (user_id, lvl_id, progress) VALUES (?, 1, 0)",user_id)
end

def get_lvl()
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    db.results_as_hash = true
    lvl_id_hash= db.execute("SELECT DISTINCT lvl_id FROM users_lvl_relationship Where user_id = ?", session[:id]) 
    lvl_id = lvl_id_hash[0]["lvl_id"]
    result = db.execute("SELECT DISTINCT lvlname FROM lvl Where id = ?", lvl_id) 
    return result[0]["lvlname"]
end

def learn_move(move_name)
    username = session[:username]
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    db.results_as_hash = true
    move_id_hash = db.execute("SELECT id FROM moves WHERE move_name = ?", move_name) 
    move_id = move_id_hash[0]["id"]
    user_id_hash = db.execute("SELECT id FROM users WHERE username = ?", username) 
    user_id = user_id_hash[0]["id"]
    db.execute("Insert INTO learning (user_id, move_id) VALUES (?,?)", user_id, move_id)
    return true
end

def learned_move(move_name)
    username = session[:username]
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    db.results_as_hash = true
    move_id_hash = db.execute("SELECT id FROM moves WHERE move_name = ?", move_name) 
    move_id = move_id_hash[0]["id"]
    user_id_hash = db.execute("SELECT id FROM users WHERE username = ?", username) 
    user_id = user_id_hash[0]["id"]
    db.execute("Insert INTO learned (user_id, move_id) VALUES (?,?)", user_id, move_id)
    db.execute("DELETE FROM learning WHERE move_id = ?", move_id)
    return true
end

def get_moves()
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM moves Where difficulty = 2") 
    return result
end

def select_moves_with_id(array_of_moves_id)
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    array_of_moves_name = []
    array_of_moves_id.each do |id|
        id = id["move_id"]
        move_name = db.execute("SELECT ")

end

def get_learning_moves()
    username = session[:username]
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    p db
    db.results_as_hash = true
    user_id_hash = db.execute("SELECT id FROM users WHERE username = ?", username) 
    user_id = user_id_hash[0]["id"]
    result = db.execute("SELECT * FROM learning Where user_id = ?", user_id) 
    p result
    p "1"
    return result
end

def get_learned_moves()
    username = session[:username]
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    p db
    db.results_as_hash = true
    result = db.execute("SELECT * FROM moves Where difficulty = 2") 
    p result
    return result
end

def new_move(move_name, move_content, difficulty, genre, img_path)
    created_by = 0
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    db.execute("INSERT INTO moves (move_name, content, difficulty, created_user_id, img_path) VALUES (?,?,?,?,?)",move_name, move_content, difficulty, created_by, img_path)
    move_id = db.execute("SELECT id FROM moves WHERE move_name = ?", move_name) 
    db.execute("Insert INTO genre_move_relationship (genre_id, move_id) VALUES (?,?)", genre, move_id)
    return true
end 

def select_difficulty(difficulty)
    db = SQLite3::Database.new('db\parkour_journey_21_db.db')
    db.results_as_hash = true

    result = db.execute("SELECT * FROM moves Where difficulty = ?", difficulty) 
    p result
    return result
end