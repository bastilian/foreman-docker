module Service
  class RegistryApi
    DOCKER_HUB = 'https://registry.hub.docker.com/'
    DEFAULTS = {
      url: 'http://localhost:5000',
      connection: { omit_default_port: true }
    }

    attr_accessor :config, :url, :user, :password

    def initialize(params = {})
      self.config = DEFAULTS.merge(params)
      self.url = config[:url]
      self.user = config[:user] unless config[:user].blank?
      self.password = config[:password] unless config[:password].blank?

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
      begin
        result = get("/v1/repositories/#{image_name}/tags")
      rescue
        result = tags_v2(image_name)
      end
      if result
        result = filter_tags(result, query) if query
        result
      else
        []
      end
    end

    def tags_v2(image_name)
      get("/v2/#{image_name}/tags/list")['tags'].map { |tag| { 'name' => tag } }
    end

    def self.docker_hub
      @@docker_hub ||= new(url: DOCKER_HUB)
    end

    private

    def credentials
      { user: user, password: password }
    end

    def filter_tags(result, query)
      result.select do |tag_name|
        tag_name['name'] =~ /^#{query}/
      end
    end
  end
end
