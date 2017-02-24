module ContainerStepsHelper
  def container_wizard(step)
    wizard_header(
      step,
      *humanized_steps
    )
  end

  def select_registry(f)
    registries = DockerRegistry.with_taxonomy_scope_override(@location, @organization)
                 .authorized(:view_registries)
    field(f, 'docker_container_wizard_states_image[registry_id]', :label => _("Registry")) do
      collection_select :docker_container_wizard_states_image, :registry_id,
                        registries,
                        :id, :name,
                        { :prompt => _("Select a registry") },
                        :class => "form-control", :disabled => registries.size == 0
    end
  end

  def humanized_steps
    [_('Preliminary'), _('Image'), _('Configuration'), _('Environment')]
  end

  def last_step?
    step == wizard_steps.last
  end

  def taxonomy_icon(taxonomy)
    taxonomy == 'locations' ? 'globe' : 'briefcase'
  end

  def tab_class(tab_name)
    active_tab.to_s == tab_name.to_s ? "active" : ""
  end

  def model_for(registry_type)
    if active_tab.to_s == registry_type.to_s
      @docker_container_wizard_states_image
    else
      DockerContainerWizardStates::Image.new(:wizard_state => @state)
    end
  end

  # el7 returns -> "name" => "docker.io: docker.io/centos",
  # while f20 returns -> "name" => "centos"
  # we need repo name to be => "docker.io/centos" for el7 and "centos" for fedora
  # to ensure proper search with respect to the tags, image creation etc.
  def cleanup_image_name(name)
    name.split.last
  end

  def image_search_wrapper_class(model)
    if model.errors.messages[:image]
      'form-group has-error'
    else
      'form-group'
    end
  end

  def tab_active?(registry)
    active_tab == registry.to_sym
  end

  def active_tab
    if @docker_container_wizard_states_image.katello?
      :katello
    elsif @docker_container_wizard_states_image.registry_id.nil?
      :hub
    else
      :registry
    end
  end
end
