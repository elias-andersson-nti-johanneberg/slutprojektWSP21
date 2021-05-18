require 'sinatra'
require 'slim'
require 'byebug'
require 'bcrypt'
require 'sqlite3'
require_relative 'C:\Users\elias.andersson9\Documents\GitHub\slutprojektWSP21\model\model.rb'

enable :sessions

include Model # Wat dis?

# Displays the home page and title of the site
#
get('/') do
  slim(:home)
end

# Displays the sign up form
#
get('/register') do
  slim(:"user/register")
end

# Attempts login and updates the session
#
# @see Model#login
post('/register/new') do 
  register_new_user()
end

# Displays the sign in form
#
get('/showlogin') do
  slim(:"user/login")
end

# Attempts login and updates the session
#
# @see Model#login
post('/login') do
  login()
end

# Displays the user page where you can find all of your account data. what lvl you are, what kind of moves you have learnt and can learn.
#
# @see Model#get_moves
# @see Model#get_learning_moves
# @see Model#get_learned_moves
# @see Model#check_lvl
# @see Model#get_lvl
get('/user') do
    username = session[:username]
    id = session[:id]
    moves_list = get_moves(username,id)
    learning_list = get_learning_moves(username)
    learned_list = get_learned_moves(username)
    user_list = get_user_list()
    check_lvl(username, learned_list,id)
    lvl = get_lvl(id)
    slim(:"user/index", locals:{username_list:user_list ,user_moves_list:moves_list,user_learning_list:learning_list, user_learned_list:learned_list, user_lvl:lvl})
  end

  #!/usr/bin/env ruby
=begin old code not used anymore
  post('/uploads') do 
    if params[:image] && params[:image][:filename]
      filename = params[:image][:filename]
      file = params[:image][:tempfile]
      path = "./public/uploads/#{filename}"
  
      # Write file to disk
      File.open(path, 'wb') do |f|
        f.write(file.read)
      end
    end
  end
=end

# Attempts to update what moves you have learned or want to learn and the redirects to '/user'
#
# @param [String] training, Information if the user has learnt or wants to learn a specific move
#
# @see Model#learn_move
# @see Model#learned_move
post('/move/learn') do 
  username = session[:username]
  learn_decision = params[:training]
  #takes the value from the form splits it up and exceutes two diffrent functions depending on the value sent.
  decision = learn_decision.split(".")
  if decision[0] == "learning"
    learn_move(decision[1],username)
  else
    learned_move(decision[1],username)
  end
  redirect('/user')
end 

# Attempts to create a new move and put it in the database and then redirects to '/created_move'
#
# @param [String] move_name, The name of the move that is being created 
# @param [String] move_content, The description of the new move
# @param [Integer] difficulty, The number signifing how hard the move is and which lvl is able to learn it. 
# @param [Integer] genre, The number singifing what class the move belongs to. 
# @param [String] image, The image of the move
# @param [String] filename, The name of the image file
# @param [String] tempfile, The data of the image file
#
# @see Model#new_move
post('/move/new') do 
  move_name = params[:move_name]
  move_content = params[:move_content]
  difficulty = params[:difficulty]
  genre = params[:genre]

  if params[:image] && params[:image][:filename]
    filename = params[:image][:filename]
    file = params[:image][:tempfile]
    img_path = "./uploads/#{filename}"

    # Write file to disk
    File.open(img_path, 'wb') do |f|
      f.write(file.read)
    end
  end
  
  new_move(move_name, move_content, difficulty, genre, img_path)

  redirect('/created_move')
end

post('/user_edit') do
  username = session[:username]
  user_decision = params[:user_edit]
  decision = user_decision.split(".")
  delete_username(decision[1])
  redirect('/user') 
end

get('/change_username') do
  slim(:"user/change_username")
end

post('/change_username') do 
  old_username = params[:old_username]
  new_username = params[:new_username]
  change_username(old_username,new_username)
  redirect('/user')
end


# Displays a page where you get feedback that you created a move and the sends you back to '/user'
#
get('/created_move') do
  slim(:"moves/created_a_move")
  
  if true == wait(5)
    redirect('/user')
  end
end

# Displays a error page with error message to indicate what went wrong
#
get('/error') do 
  session[:error]
end

