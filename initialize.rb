require "daybreak"

DB = Daybreak::DB.new "#{Dir.getwd}/database.db"

DB["404"] = {
  :type   => "e",
  :title  => "Not Found",
  :id     => "404",
  :webm   => "/404.webm",
  :mp4    => "/404.mp4",
  :thumbnail => "/404.png",
  :width  => "500",
  :height => "500"
}

DB.flush
DB.close