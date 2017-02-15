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

    def validate_image_exists
      unless compute_resource.exist? "#{repository_name}:#{tag}"
        errors.add(:image, "Docker Image does not exist!")
      end
    end
  end
end
