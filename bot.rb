require 'httparty'
require 'json'
require 'uri'

module BSF
  YT_API_KEY = ''      # API ключ для YT
  VK_ACCESS_TOKEN = '' # API токен для VK
  VK_OWNER_ID = ''     # ID группы

  class << self
    def init
      get_data_from_youtube( 'UCQBEHg0j6baNS1Lya-L4BJw' )
    
      gets
    end

    def get_data_from_youtube( channel )
      resp = JSON.parse(
        HTTParty.get( 
          "https://www.googleapis.com/youtube/v3/activities?part=snippet,contentDetails&maxResults=50&channelId=#{ channel }&key=#{ YT_API_KEY }",
          :verify => false
        ).body,
        :symbolize_names => true
      )

      resp[ :items ].each do | item |
        if item[ :snippet ][ :type ] != "upload" then
          next
        end

        post_VK( item[ :snippet ][ :title ], item[ :contentDetails ][ :upload ][ :videoId ] )
      end
    end

    def post_VK( title, link )
      l = "https://www.youtube.com/watch?v=#{ link }"
      msg = "Новое видео:\n#{ title }\n#{ l }"

      resp = JSON.parse(
        HTTParty.post(
          URI.escape( "https://api.vk.com/method/wall.post?owner_id=#{ VK_OWNER_ID }&from_group=1&message=#{ msg }&signed=0&attachments=#{ l }&access_token=#{ VK_ACCESS_TOKEN }" ),
          :verify => false
        ).body,
        :symbolize_names => true
      )
      
      puts resp
    end
  end
end

BSF.init
