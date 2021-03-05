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

def get_moves()
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