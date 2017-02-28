module Service
  class RegistryApi
    DOCKER_HUB = 'https://registry.hub.docker.com/'
    DEFAULTS = {
      url: 'http://localhost:5000',
      connection: { omit_default_port: true }
    }

    attr_accessor :config, :url

    def initialize(params = {})
      self.config = DEFAULTS.merge(params)
      self.url = config[:url]
      @user = config[:user] unless config[:user].blank?
      @password = config[:password] unless config[:password].blank?

      Docker.logger = Rails.logger if Rails.env.development?
    end

    def connection
      @connection ||= ::Docker::Connection.new(url, credentials)
    end

    def get(path, params = nil)
      response = connection.get('/', params,
                                DEFAULTS[:connection].merge({ path: "#{path}" }))
      response = JSON.parse(response) rescue
      response
    end

    # Since the Registry API v2 does not support a search the v1 endpoint is used
    # Newer registries will fail, the v2 catalog endpoint is used
    def search(query)
      get('/v1/search', { q: query })
    rescue
      { 'results' => catalog(query) }
    end

    # Some Registries might have this endpoint not implemented/enabled
    def catalog(query)
      get('/v2/_catalog')['repositories'].select do |image|
        image =~ /^#{query}/
      end.map { |image_name| { 'name' => image_name } }
    end

    def tags(image_name, query = nil)
      result = get_tags(image_name)
      result = filter_tags(result, query) if query
      result
    end

    def ok?
      get('/v1/').match("Docker Registry API")
    rescue
      get('/v2/').is_a? Hash
    end

    def self.docker_hub
      @@docker_hub ||= new(url: DOCKER_HUB)
    end

    private

    def get_tags(image_name)
      get("/v1/repositories/#{image_name}/tags")
    rescue
      tags_v2(image_name)
    end

    def tags_v2(image_name)
      get("/v2/#{image_name}/tags/list")['tags'].map { |tag| { 'name' => tag } }
    end

    def credentials
      { user: @user, password: @password }
    end

    def filter_tags(result, query)
      result.select do |tag_name|
        tag_name['name'] =~ /^#{query}/
      end
    end
  end
end
