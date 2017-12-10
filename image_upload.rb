require 'fileutils'

class ImageUpload
  attr_reader :file, :error

  VALID_EXTENSIONS = ['jpeg', 'png', 'gif', 'jpg'].freeze 
  MAX_FILE_SIZE = 20000000 # 20MB

  def initialize(image_params)
    @error = ''
    @error = 'No image provided.' and return unless valid_params?(image_params)
    @extension = image_params[:type].split("/")[1]
    @error = 'Supported image types are: jpeg, gif and png.' and return unless valid_extension? @extension
    @temp_file_path = image_params[:tempfile].path
    file = File.new(@temp_file_path)
    @error = 'File larger than 20,000 KB.' and return if file.size > MAX_FILE_SIZE
    @valid = true
  end

  def save!
    @path = "#{File.dirname(__FILE__)}/static/upload/#{SecureRandom.uuid}.#{@extension}"
    file = FileUtils.cp(@temp_file_path, @path)
    if File.exists? @path
      return true
    else
      @error = 'Internal error. [1]' and return false
    end
  end

  def file_name
    @path.split("/")[-1]
  end

  def valid?
    @error.empty?
  end

  private

  def valid_extension?(ext)
    VALID_EXTENSIONS.include? ext
  end

  def valid_params?(image_params)
    image_params && image_params[:type] && image_params[:type].include?("/")
  end
end
