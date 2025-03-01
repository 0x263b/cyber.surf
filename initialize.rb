require "lmdb"
require "json"

env = LMDB.new "#{Dir.getwd}/database", :mapsize => 26210000
DB  = env.database

error_404 = {
  :type   => "e",
  :title  => "Not Found",
  :id     => "404",
  :webm   => "/404.webm",
  :mp4    => "/404.mp4",
  :thumbnail => "/404.png",
  :width  => "500",
  :height => "500"
}

DB.put("404", error_404.to_json)

env.close