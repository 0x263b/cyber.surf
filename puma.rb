threads 1, 6
workers 1

root = "#{Dir.getwd}"
 
bind "unix://#{root}/var/run/puma.sock"

stdout_redirect "#{root}/var/log/puma.stdout.log", "#{root}/var/log/puma.stderr.log", true

pidfile "#{root}/var/run/puma.pid"
state_path "#{root}/var/run/state"

rackup "#{root}/config.ru"
