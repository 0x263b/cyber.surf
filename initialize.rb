# encoding: utf-8
require "leveldb-native"
require "json"

DB = LevelDBNative::DB.new "#{Dir.getwd}/database"

DB["404"] = {
  :type   => "e",
  :title  => "Not Found",
  :id     => "404",
  :webm   => "/404.webm",
  :mp4    => "/404.mp4",
  :thumbnail => "/404.png",
  :width  => "500",
  :height => "500"
}.to_json
