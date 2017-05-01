module Service
  class RegistryApi
    DEFAULTS = { :url => 'http://localhost:5000' }
    attr_reader :config

    def initialize(params = {})
      config = DEFAULTS.merge(params)
      uri = URI(config.delete(:url))
      uri.user = config.delete(:user) unless config[:user].blank?
      uri.password = config.delete(:password) unless config[:password].blank?
      @config = config.merge(:url => uri.to_s)
    end

    def search(aquery)
      RestClient.proxy = SETTINGS.fetch(:foreman_docker, {}).fetch(:http_proxy, nil)
      response = RestClient.get(config[:url] + '/v1/search',
                                :params => { :q => aquery }, :accept => :json)
      RestClient.proxy = nil
      JSON.parse(response.body)
    end

    def list_repository_tags(arepository)
      RestClient.proxy = SETTINGS.fetch(:foreman_docker, {}).fetch(:http_proxy, nil)
      response = RestClient.get(config[:url] + "/v1/repositories/#{arepository}/tags",
                                :accept => :json)
      RestClient.proxy = nil
      JSON.parse(response.body)
    end
  end
end
