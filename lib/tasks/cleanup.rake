namespace :cleanup do
  task :tables do
    tables = [
      :containers,
      :docker_images,
      :docker_tags,
      :docker_registries,
      :docker_image_docker_registries,
      :docker_container_wizard_states,
      :docker_container_wizard_states_preliminaries,
      :docker_container_wizard_states_images,
      :docker_container_wizard_states_configurations,
      :docker_container_wizard_states_environments,
      :docker_parameters
    ]
    tables.each do |table|
      ActiveRecord::Migration.drop_table table
    end
  end
end
