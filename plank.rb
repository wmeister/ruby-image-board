require 'sinatra'
require 'securerandom'
require 'fileutils'
require 'redis'
require 'json'
require 'date'
require_relative 'image_upload'
require_relative 'board_repository'

$redis = Redis.new
$main_layout = "layout/main".to_sym

enable :sessions

set :bind, 'localhost'
set :public_folder, File.dirname(__FILE__) + '/static'

helpers do
  def post_error(msg)
    @params = params
    @error = msg
    status, headers, body = call env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => '/dev') # XXX shouldnt be hardcoded
    body
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  erb :index, :layout => $main_layout
end

post '/post' do  
  image = ImageUpload.new(params[:image])
  board = BoardRespository.find(params[:id].to_i)
  return post_error("Board does not exist.") if board.nil?

  if /^\s*$/.match(params[:title]) || /^\s*$/.match(params[:body])
    return post_error "Fields cannot be blank."
  else
    return post_error image.error unless image.valid? && image.save!
  end
  
  # our img is ready in img_path if they attached one
  id = "post:#{SecureRandom.uuid}"
  $redis.set id, JSON.dump(
    title: params[:title],
    body:  params[:body],
    image: image.file_name,
    time:  DateTime.now
  )
  $redis.rpush "board:#{board.id}", id
  redirect to("#{board.path}?success=1")
end

# Boards
get '/:board_name' do
  repo = BoardRepository.new
  board = repo.find_by_name(params[:board_name])
  return post_error "Board not found" if board.nil?
  @id          = board.id
  @description = board.description
  @title       = board.path
  @path        = board.path
  @posts       = board.posts
  erb :board, layout: $main_layout  
end
