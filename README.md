# cyber.surf

Built using Ruby ([Sinatra](https://github.com/sinatra/sinatra), [Puma](https://github.com/puma/puma), [Daybreak](https://github.com/propublica/daybreak)), with [Imgur](https://api.imgur.com/), [Gfycat](https://gfycat.com/api), and [Reddit](https://www.reddit.com/dev/api).

Gif info is stored in a [daybreak database](app.rb#L52-L56), and API calls are stored as [plaintext](app.rb#L26-L50) on the server.

#### Testing locally

First, get an [imgur API Client ID](https://api.imgur.com/oauth2/addclient) and edit [app.rb#L18](app.rb#L18)

Clone the repo, run [initialize.rb](initialize.rb) to build the database, then `rackup` to run the server. 

To run a production, take a look at [nginx.conf](nginx.conf) (nginx proxy pass config) and [cybersurf.conf](cybersurf.conf) (Ubuntu upstart config).