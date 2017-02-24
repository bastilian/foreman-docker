class ImageSearchController < ::ApplicationController
  before_filter :find_resource

  # this is incredibly odd. for some reason, rails sees the
  # requests ImageSearchControllerTest makes as requests from another host
  # thus, violating CSRF.
  protect_from_forgery :only => :nothing if Rails.env.test?

  def search_repository
    catch_network_errors do
      repositories = image_search_service.search(term: params[:search])

      respond_to do |format|
        format.js do
          render :partial => 'repository_search_results',
                 :locals  => { :repositories => repositories }
        end
      end
    end
  end

  def auto_complete
    catch_network_errors do
      results = image_search_service.search({term: params[:search], tags: params[:tags]})

      respond_to do |format|
        format.js { render json: prepare_autocomplete_results(results) }
      end
    end
  end

  private

  def image_search_service
    @image_search_service ||= ::ForemanDocker::ImageSearch.new(@compute_resource, @registry)
  end

  def prepare_autocomplete_results(results)
    results.map do |result|
      { label: CGI.escapeHTML(result['name']),
        value: CGI.escapeHTML(result['name']) }
    end.uniq
  end

  def catch_network_errors
    yield
  rescue Docker::Error::NotFoundError => e
    # not an error
    logger.debug "image not found: #{e.backtrace}"
    render :js, :nothing => true
  rescue Docker::Error::DockerError, Excon::Errors::Error, Errno::ECONNREFUSED => e
    render :js => _("An error occured during repository search: '%s'") % e.message,
           :status => 500
  end

  def action_permission
    case params[:action]
    when 'auto_complete', 'search_repository'
      :search_repository
    else
      super
    end
  end

  def find_resource
    if params[:registry_id].present? && !params[:registry_id].blank?
      @registry = DockerRegistry.authorized(:view_registries).find(params[:registry_id])
    else
      @compute_resource = ComputeResource.authorized(:view_compute_resources).find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end
end
