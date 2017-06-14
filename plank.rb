require 'sinatra'
require 'securerandom'
require 'fileutils'

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
end

get '/' do
  erb :index, :layout => $main_layout
end

get '/dev' do # XXX needs smarter way to match boards route
  board = $boards[0]
  board(board)
  @title = @path
  erb :board, :layout => $main_layout  
end

post '/post' do  
  img = params[:image]
  boards = $boards.collect{|b| b if b[:id].to_s == params[:id]}
  return post_error("Board does not exist.") unless boards.size == 1
  board = boards[0]
  img_path = nil

  if /^\s*$/.match(params[:title]) || /^\s*$/.match(params[:body])
    return post_error "Fields cannot be blank."
  else
    if img && img[:type] && img[:type].include?("/")
      ext = img[:type].split("/")[1]
      
      if ['jpeg', 'png', 'gif', 'jpg'].include? ext
        temp = img[:tempfile].path

        if File.new(temp).size < 20000000 # 20,000 Kb
          path = "#{File.dirname(__FILE__)}/static/upload/#{SecureRandom.uuid}.#{ext}"
          FileUtils.cp(temp, path)
          if File.exists? path
            # success
            img_path = path
          else # error copying
            return post_error "Internal error. [1]"
          end
        else # image too large
          return post_error "File larger than 20,000 Kb."
        end
      else # unknown image type
        return post_error "Supported image types are: jpeg, gif and png."
      end
    else # error determining mime type
      if !img.nil?
        return post_error "Internal error. [2]"
      end
    end
  end
  
  # our img is ready in img_path if they attached one
  # XXX save the post

  
  redirect to(board[:path]+'?success=1')
end
