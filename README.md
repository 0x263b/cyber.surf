# cyber.surf

[![](https://raw.githubusercontent.com/0x263b/cyber.surf/master/public/icons/76.png)](https://cyber.surf)

Built using Ruby ([Sinatra](https://github.com/sinatra/sinatra), [Puma](https://github.com/puma/puma), [LMDB](https://github.com/minad/lmdb)), with [Imgur](https://api.imgur.com/), [Gfycat](https://gfycat.com/api), and [Reddit](https://www.reddit.com/dev/api).

Gif info is stored in a LMDB database, and API calls are stored as plaintext on the server.

#### Testing locally

First, get an [imgur API Client ID](https://api.imgur.com/oauth2/addclient). 

Clone the repo, and `bundle install` the dependencies. Edit `config.ru` with your Client ID. Run [initialize.rb](initialize.rb) to build the database, then `rackup` to run the server.
