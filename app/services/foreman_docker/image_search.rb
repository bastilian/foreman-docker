module ForemanDocker
  class ImageSearch
    attr_accessor :compute_resource, :registry

    def initialize(compute_resource, registry)
      @compute_resource = compute_resource
      @registry = registry ? registry.api : Service::RegistryApi.docker_hub
    end

    def add_source(source)
      @sources ||= {}
      case source
      when ForemanDocker::Docker
        @sources[:compute_resource] ||= []
        @sources[:compute_resource] << source
      when DockerRegistry
        @sources[:registry] ||= []
        @sources[:registry] << source
      end
    end

    def search(query)
      return [] if query[:term].blank? || query[:term] == ':'

      unless query[:tags] == 'true'
        images(query[:term])
      else
        tags(query[:term])
      end
    end

    def images(query)
      result = []
      result += search_compute_resource(query) if compute_resource
      result += search_registry(query) if registry
    end

    def tags(query)
      result = []
      image_name, tag = query.split(':')
      result += compute_resource_tags(image_name, tag) if compute_resource
      result += registry_tags(image_name, tag) if registry
      result.map { |tag_name| { 'name' => tag_name } }
    end

    def available?(query)
      tags(query).present?
    end

    private

    def search_registry(term)
      registry.search(term)['results']
    end

    def search_compute_resource(query)
      images = compute_resource.local_images(query)
      images.flat_map do |image|
        image.info['RepoTags'].map do |tag|
          { 'name' => tag.split(':').first }
        end
      end.uniq
    end

    def compute_resource_tags(image_name, tag)
      image = compute_resource.image(image_name) rescue nil
      image ? compute_resource.tags_for_local_image(image, tag) : []
    end

    def registry_tags(image_name, tag)
      registry.tags(image_name, tag).map { |t| t['name'] }
    end
  end
end

