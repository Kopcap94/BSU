require 'httparty'
require 'json'
require 'uri'

module BSU
  PATH = File.dirname(__FILE__)
  CFG_PATH = PATH + '/config.json'

  class << self
    def init
      puts "Loading CFG"
      @cfg = JSON.parse( File.read( CFG_PATH ) )
      @cfg_mutex = Mutex.new
      @thread = nil

      check_thread

      gets
    end

    def check_thread
      @thread = Thread.new {
        begin
          @cfg[ 'last' ].each do | k, v |
            get_data( k )
          end

          sleep 300
          check_thread
        rescue => err
          puts err
          check_thread
        end
      }
    end

    def get_data( channel )
      resp = JSON.parse(
        HTTParty.get( 
          "https://www.googleapis.com/youtube/v3/search?part=snippet,id&order=date&maxResults=50&channelId=#{ channel }&key=#{ @cfg[ 'youtube' ] }",
          :verify => false
        ).body,
        :symbolize_names => true
      )

      last = nil
      to_publish = []

      resp[ :items ].each_with_index do | item, index |
        id = item[ :id ][ :videoId ]

        break if id == @cfg[ 'last' ][ channel ]

        if index == 0 then
          last = id
        end

        title = item[ :snippet ][ :title ]
        link = "https://www.youtube.com/watch?v=#{ id }"

        to_publish.push( [ title, link ] )
      end

      if !to_publish.empty? then
        @cfg[ 'last' ][ channel ] = last
        save_cfg

        post_VK( to_publish )
      end
    end

    def post_VK( array )
      array.each do | post |
        l = post[ 1 ]
        msg = "#{ post[ 0 ] }\n#{ l }"

        resp = JSON.parse(
          HTTParty.post(
            URI.escape( "https://api.vk.com/method/wall.post?owner_id=#{ @cfg[ 'group' ] }&from_group=1&message=#{ msg }&signed=0&attachments=#{ l }&access_token=#{ @cfg[ 'vk' ] }" ),
            :verify => false
          ).body,
          :symbolize_names => true
        )

        sleep 10
      end
    end

    def save_cfg
      @cfg_mutex.synchronize do
        File.open( CFG_PATH, 'w+' ) {|f| f.write( JSON.pretty_generate( @cfg ) ) }
      end
    end
  end
end

BSU.init
