require "sinatra"
configure do
	set :imgur, "xxxxxxxxxxxxxxx"
end

require "./app"
run Sinatra::Application