class Board
  attr_reader :id, :path, :description, :posts

  def initialize(attrs)
    @id          = attrs[:id]
    @path        = attrs[:path]
    @description = attrs[:description]
    @posts       = get_posts
  end

  private

  def get_posts
    posts = []
    i = 1
    
    for post_id in $redis.lrange "board:#{@id}", 0, -1
      post = JSON.parse($redis.get(post_id))
      post['alt'] = i % 2
      post['id'] = post_id.split(":")[-1]
      post['path'] = '/post/' + post['id']
      posts << post
      i += 1
    end
    posts.sort{ |a,b| DateTime.parse(b['time']) <=> DateTime.parse(a['time']) }
  end
end
