require 'rest-client'
require 'json'

module Blinker
  module Ctf
    class FilestoreClient
      def initialize hash
        @api = hash[:api] || raise('no api url given')
        @public = hash[:public] || raise('no public url given')

        @api.gsub!(/\/*\z/,'')
        @public.gsub!(/\/*\z/,'')
      end

      def upload uuid, path
        res = RestClient.post "#{@api}/upload", uuid: uuid, file: File.new(path, 'rb')

        raise "upload failed, status code #{res.code}" unless res.code == 200

        res = JSON.parse(res.body)

        raise "upload failed: #{res}" unless res['result'] == 'ok'
        raise 'api error: no filename returned' unless res['filename']
        "#{@public}/#{res['filename']}"
      end
    end
  end
end
