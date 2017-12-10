require 'sinatra'
require 'securerandom'
require 'fileutils'
require 'redis'
require 'json'
require 'date'
require_relative 'image_upload'

$redis = Redis.new
$main_layout = "layout/main".to_sym
$boards = [
  {
    id: 1,
    path: "/dev",
    description: "development board"
  }
]

enable :sessions

set :bind, '10.0.0.6'
set :public_folder, File.dirname(__FILE__) + '/static'

helpers do
  def board(board)
    @path = board[:path]
    @description = board[:description]
    @id = board[:id]
  end

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

def get_posts(board_id)
  posts = []
  i = 1
  
  for post_id in $redis.lrange "board:#{board_id}", 0, -1
    post = JSON.parse($redis.get(post_id))
    post['alt'] = i % 2
    post['id'] = post_id.split(":")[-1]
    post['path'] = '/post/'+post['id']
    posts << post
    i += 1
  end
  posts.sort{|a,b| DateTime.parse(b['time']) <=> DateTime.parse(a['time'])}
end

get '/' do
  erb :index, :layout => $main_layout
end

get '/dev' do # XXX needs smarter way to match boards route
  b = $boards[0]
  board(b)
  @title = @path
  @posts = get_posts(b[:id])
  erb :board, :layout => $main_layout  
end

post '/post' do  
  image = ImageUpload.new(params[:image])
  boards = $boards.collect{|b| b if b[:id].to_s == params[:id]}
  return post_error("Board does not exist.") unless boards.size == 1
  board = boards[0]

  if /^\s*$/.match(params[:title]) || /^\s*$/.match(params[:body])
    return post_error "Fields cannot be blank."
  else
    return post_error image.error unless image.valid? && image.save!
  end
  
  # our img is ready in img_path if they attached one
  id = "post:#{SecureRandom.uuid}"
  $redis.set id, JSON.dump({title: params[:title], body: params[:body], image: image.file_name, time: DateTime.now})
  $redis.rpush "board:#{board[:id]}", id
  redirect to(board[:path]+'?success=1')
end
