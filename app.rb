require 'sinatra'
require 'slim'
require 'byebug'
require 'bcrypt'
require 'sqlite3'
require_relative 'model.rb'

enable :sessions

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
    lvl = get_lvl()
    slim(:"user/index", locals:{user_moves_list:moves_list, user_lvl:lvl})
  end

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

  post('/move/learn') do 
    p params[:training]
    
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