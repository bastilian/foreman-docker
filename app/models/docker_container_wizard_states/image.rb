module DockerContainerWizardStates
  class Image < ActiveRecord::Base
    self.table_name_prefix = 'docker_container_wizard_states_'
    belongs_to :wizard_state, :class_name => DockerContainerWizardState,
                              :foreign_key => :docker_container_wizard_state_id
    delegate :compute_resource_id, :to => :wizard_state
    delegate :compute_resource, :to => :wizard_state

    validates :tag,             :presence => true
    validates :repository_name, :presence => true
    validate :validate_image_exists

    def name
      "#{repository_name}:#{tag}"
    end

    def registry_name
      @registry_name ||= if registry_id
        DockerRegistry.find(registry_id).fetch(:name, _('Unnamed Registry'))
      else
        _('Compute resource or Docker Hub')
      end
    end

    def validate_image_exists
      unless compute_resource.exist? name
        error_msg = _("Container image %{image_name} could not be found on %{registry}.") % {
          image_name: name,
          registry: registry_name
        }
        errors.add(:image, error_msg)
      end
    end
  end
end
