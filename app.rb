require 'sinatra'
require 'slim'
require 'byebug'
require 'bcrypt'
require 'sqlite3'
require_relative 'C:\Users\elias.andersson9\Documents\GitHub\slutprojektWSP21\model\model.rb'

enable :sessions

include Model

get('/') do
  slim(:home)
end

get('/register') do
  slim(:"user/register")
end

post('/register/new') do 
  register_new_user()
end

get('/showlogin') do
  slim(:"user/login")
end

post('/login') do
  login()
end

get('/user') do
    moves_list = get_moves()
    learning_list = get_learning_moves()
    learned_list = get_learned_moves()
    check_lvl(session[:username], learned_list)
    lvl = get_lvl()
    slim(:"user/index", locals:{user_moves_list:moves_list,user_learning_list:learning_list, user_learned_list:learned_list, user_lvl:lvl})
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

post('/move/learn') do 
  learn_decision = params[:training]
    decision = learn_decision.split(".")
    if decision[0] == "learning"
    learn_move(decision[1])
    else
    learned_move(decision[1])
    end
  redirect('/user')
end 

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
  p img_path
  new_move(move_name, move_content, difficulty, genre, img_path)

  redirect('/created_move')
end


get('/created_move') do
  slim(:"moves/created_a_move")
  
  if true == wait(5)
    redirect('/')
  end
end

get('/error') do 
  session[:error]
end

