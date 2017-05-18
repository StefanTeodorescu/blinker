require 'rest-client'
require 'json'
require 'securerandom'

module Blinker
  module Ctf
    class AptlyClient
      def initialize api_url
        @api = api_url.gsub(/\/*\z/,'') + '/api'
      end

      def submit_package package, repo
        prefix, distribution = find_published_repo repo
        file = api_upload_file package
        api_add_to_repo file, repo
        api_update_repo prefix, distribution
      end

      protected
      def api_upload_file package
        id = SecureRandom.hex 16
        file = "#{id}/#{File.basename package}"

        res = RestClient.post "#{@api}/files/#{id}", file: File.new(package, 'rb')
        raise "upload failed, status code #{res.code}" unless res.code == 200

        res = JSON.parse(res.body)
        raise "upload failed: #{res}" unless res == [file]

        file
      end

      def api_add_to_repo file, repo
        res = RestClient.post "#{@api}/repos/#{repo}/file/#{file}", {}
        raise "request failed, status code #{res.code}" unless res.code == 200

        res = JSON.parse(res.body)
        raise "api error: #{res}" unless res['FailedFiles'] and res['Report'] and res['Report']['Added']
        raise "upload failed: #{res}" if res['FailedFiles'].length > 0 or res['Report']['Added'].empty?

        true
      end

      def api_update_repo prefix, distribution
        res = RestClient.put "#{@api}/publish/#{prefix}/#{distribution}", {}
        raise "request failed, status code #{res.code}" unless res.code == 200

        res = JSON.parse(res.body)
        raise "api error: #{res}" unless res['Prefix'] == prefix and res['Distribution'] == distribution

        true
      end

      def api_get_published
        res = RestClient.get "#{@api}/publish"
        raise "request failed, status code #{res.code}" unless res.code == 200

        res = JSON.parse(res.body)
        raise "api error: #{res}" unless res.is_a? Array

        res
      end

      def find_published_repo repo
        published_repos = api_get_published.select { |repo_def|
          next false unless repo_def['SourceKind'] == 'local'
          next false unless repo_def['Sources']&.length == 1
          repo_def['Sources'].first['Name'] == repo
        }

        raise 'unsupported repo configuration' unless published_repos.length == 1

        ['Prefix', 'Distribution'].map { |k| published_repos.first[k] }
      end
    end
  end
end
