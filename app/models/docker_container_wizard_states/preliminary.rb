module DockerContainerWizardStates
  class Preliminary < ApplicationRecord
    include Taxonomix

    self.table_name_prefix = 'docker_container_wizard_states_'
    belongs_to :wizard_state, :class_name => DockerContainerWizardState,
                              :foreign_key => :docker_container_wizard_state_id

    belongs_to :compute_resource, :required => true

    def used_location_ids
      Location.joins(:taxable_taxonomies).where(
        'taxable_taxonomies.taxable_type' => 'DockerContainerWizardStates::Preliminary',
        'taxable_taxonomies.taxable_id' => id).pluck("#{Taxonomy.table_name}.id")
    end

    def used_organization_ids
      Organization.joins(:taxable_taxonomies).where(
        'taxable_taxonomies.taxable_type' => 'DockerContainerWizardStates::Preliminary',
        'taxable_taxonomies.taxable_id' => id).pluck("#{Taxonomy.table_name}.id")
    end
  end
end
