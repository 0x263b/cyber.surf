# encoding: utf-8
require 'sinatra'
require 'open-uri'
require 'json'
require 'tilt/erb'
require 'date'
require 'daybreak'
require 'digest/md5'

configure { 
  set :server, :puma
  set :environment, :production
}

root = "#{Dir.getwd}"
DB = Daybreak::DB.new "#{Dir.getwd}/database.db"
TMP = "#{Dir.getwd}/tmp"

IMGUR = "Client-ID xxxxxxxxxxxxxxx"

helpers do 
  at_exit do
    DB.compact
    DB.close
  end

  def cache_api(url, type = "any")
    file = Digest::MD5.hexdigest(url)
    file_path = File.join("", TMP, file)
    if File.exists? file_path
      if File.mtime(file_path).to_i > (Time.now.to_i / 3600) * 3600
        data = File.read(file_path)
        return JSON.parse(data, {:symbolize_names => true})
      end
    end

    data = get_api(url, type)
    File.open(file_path, "w") { |file| file.write(data.to_json) }

    return data
  end

  def get_api(url, type)
    if type == "imgur"
      doc = open(url, "Authorization" => IMGUR).read
    else
      doc = open(url).read
    end

    return JSON.parse(doc, {:symbolize_names => true})  
  end

  def save(key, value)
    DB.synchronize do
      DB.set!(key, value)
    end
  end

  def gfycat_url(post_id, title = nil)
    return if post_id.nil?
    post_id = post_id.downcase
    return DB[post_id] if DB.keys.include?(post_id)
    begin
      url = "https://gfycat.com/cajax/get/#{post_id}"
      doc = open(url).read
      res = JSON.parse(doc, {:symbolize_names => true})

      post = res[:gfyItem]

      title = post[:title] if title.nil?
      title = "Untitled" if title.nil?

      value = {
        :type   => "g",
        :title  => title,
        :id     => post[:gfyId],
        :webm   => post[:webmUrl].gsub(/^http:\/\//, "https://"),
        :mp4    => post[:mp4Url].gsub(/^http:\/\//, "https://"),
        :thumbnail => "https://thumbs.gfycat.com/#{post[:gfyName]}-poster.jpg",
        :width  => post[:width],
        :height => post[:height]
      }

      save(post_id, value)
      return DB[post_id]
    rescue
      return nil
    end
  end

  def imgur_url(post_id, title = nil)
    return if post_id.nil?
    return DB[post_id] if DB.keys.include?(post_id)

    url = "https://api.imgur.com/3/image/#{post_id}"
    begin
      doc = open(url, "Authorization" => IMGUR).read
      res = JSON.parse(doc, {:symbolize_names => true})

      post = res[:data]

      return if res[:success] == false or post[:nsfw] == true or post[:animated] == false

      title = post[:title] if title.nil?
      title = "Untitled" if title.nil?

      value = {
        :type   => "i",
        :title  => title,
        :id     => post[:id],
        :webm   => post[:webm].gsub(/^http:\/\//, "https://"),
        :mp4    => post[:mp4].gsub(/^http:\/\//, "https://"),
        :thumbnail => "https://i.imgur.com/#{post_id}h.jpg",
        :width  => post[:width],
        :height => post[:height]
      }

      save(post_id, value)
      return DB[post_id]
    rescue
      return nil
    end
  end

  def imgur_gifs(page = 0)
    begin
      res = cache_api("https://api.imgur.com/3/gallery/hot/time/#{page}.json", "imgur")

      posts = res[:data]
      images = Array.new

      posts.each do |post|
        next if post[:nsfw] == true or post[:animated] == false or post[:is_album] == true

        value = {
          :type   => "i",
          :title  => post[:title],
          :id     => post[:id],
          :webm   => post[:webm].gsub(/^http:\/\//, "https://"),
          :mp4    => post[:mp4].gsub(/^http:\/\//, "https://"),
          :thumbnail => "https://i.imgur.com/#{post[:id]}h.jpg",
          :width  => post[:width],
          :height => post[:height]
        }

        save(post[:id], value)
        images << value
      end

      after = "?cat=imgur&page=#{page+1}"

      return [random_gifs, ""] if images.empty?
      return [images, after]
    rescue
      return [random_gifs, ""]
    end
  end

  def reddit_gifs(subreddit, after = nil)
    return unless ["aww", "funny", "gifs", "woahdude"].include?(subreddit)
    begin
      url = "https://www.reddit.com/r/#{subreddit}/hot.json"
      url += "?after=#{after}" unless after.nil?

      res = cache_api(url, "reddit")
      posts = res[:data][:children]

      images = Array.new

      posts.each do |post|
        next if post[:data][:over_18] == true or post[:data][:score] < 100 

        title = post[:data][:title]

        if post[:data][:domain] == "i.imgur.com"
          post_id = post[:data][:url][/https?:\/\/i\.imgur\.com\/(\w+)\.gifv?/,1]
          image = imgur_url(post_id, title)

        elsif post[:data][:domain] == "imgur.com"
          next if post[:data][:media].nil? or post[:data][:media][:oembed][:type] != "video"
          post_id = post[:data][:url][/https?:\/\/imgur\.com\/(?:gallery\/)?(\w+)/,1]
          image = imgur_url(post_id, title)

        elsif post[:data][:domain] == "gfycat.com"
          post_id = post[:data][:url][/https?:\/\/gfycat\.com\/(\w+)/,1]
          image = gfycat_url(post_id, title)

        elsif post[:data][:domain] =~ /\w+\.gfycat\.com/
          post_id = post[:data][:url][/https?:\/\/\w+\.gfycat\.com\/(\w+)\.?\w*/,1]
          image = gfycat_url(post_id, title)

        end

        next if image.nil?
        images << image
      end

      after = "?cat=#{subreddit}&page=#{res[:data][:after]}"

      return [random_gifs, ""] if images.empty?
      return [images, after]
    rescue
      return [random_gifs, ""]
    end
  end

  def random_gifs()
    keys = DB.keys.sample(24)
    gifs = Array.new
    keys.each do |key|
      gifs << DB[key]
    end
    return gifs
  end
end

get "/" do
  begin
    @output = random_gifs
    @after = ""
    @selected = "#"
    erb :index
  rescue
    404
  end
end

get "/imgur" do
  begin
    @output, @after = imgur_gifs
    @selected = "imgur"
    erb :index
  rescue
    404
  end
end

get "/reddit-:id" do
  begin
    raise unless ["aww", "funny", "gifs", "woahdude"].include?(params[:id])
    @output, @after = reddit_gifs(params[:id])
    @selected = "reddit-#{params[:id]}"
    erb :index
  rescue
    404
  end
end

get "/get.json" do
  begin
    if params[:cat].nil? or params[:page].nil?
      @output = {:data => random_gifs, :status => "ok"}
    elsif params[:cat] == "imgur"
      data, after = imgur_gifs(params[:page].to_i)
      @output = {:data => data, :status => "ok", :after => after}
    else
      data, after = reddit_gifs(params[:cat], params[:page])
      @output = {:data => data, :status => "ok", :after => after}
    end
    content_type :json
      @output.to_json
  rescue
    content_type :json
      '{"error_code": 1, "status": "error"}'
  end
end

# Imgur
get "/i/:image" do
  begin
    post_id = params[:image]
    data = Array.new(1, DB[post_id])
    data << random_gifs
    data.flatten!

    @output = data
    @after = ""
    @selected = "#"
    erb :index
  rescue
    404
  end
end

# Gfycat
get "/g/:image" do
  begin
    post_id = params[:image].downcase
    data = Array.new(1, DB[post_id])
    data << random_gifs
    data.flatten!

    @output = data
    @after = ""
    @selected = "#"
    erb :index
  rescue
    404
  end
end

# Error handling
not_found do
  data = Array.new(1, DB["404"])
  data << random_gifs
  data.flatten!

  @output = data
  @after = ""
  @selected = "#"

  status 404
  erb :index
end