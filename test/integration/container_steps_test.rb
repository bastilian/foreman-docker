require 'integration_test_helper'

class ContainerStepsTest < IntegrationTestWithJavascript
  let(:wizard_state) { DockerContainerWizardState.create! }
  let(:compute_resource) { FactoryGirl.create(:docker_cr) }
  let(:image_search_service) { ForemanDocker::ImageSearch.new }

  setup do
    stub_image_existance
    stub_registry_api
    ImageSearchController.any_instance.stubs(:image_search_service)
                         .returns(image_search_service)
  end

  describe 'on preliminary step' do
    test 'it shows docker compute resources' do
      compute_resource.save
      visit wizard_state_step_path(:wizard_state_id => wizard_state, :id => :preliminary)
      assert_text compute_resource.name
    end
  end

  describe 'on image step' do
    let(:preliminary) do
      DockerContainerWizardStates::Preliminary.create!({
        :wizard_state => wizard_state,
        :compute_resource => compute_resource
      })
    end

    setup do
      wizard_state.preliminary = preliminary
    end

    test 'clicking on search loads repositories' do
      visit wizard_state_step_path(:wizard_state_id => wizard_state, :id => :image)
      image_search_service.expects(:search).returns([{'name' => 'my_fake_repository_result',
                                                     'star_count' => 300,
                                                     'description' => 'fake repository'}])
      fill_in 'hub_docker_container_wizard_states_image_repository_name', :with => "fake"
      find('#search_repository_button_hub').click
      assert_text 'my_fake_repository_result'
    end
  end

  context 'when no compute resources are available' do
    test 'shows a link to a new compute resource if none is available' do
      visit new_container_path
      assert has_selector?("div.alert", :text => 'Please add a new one')
    end
  end

  test 'shows taxonomies tabs' do
    visit new_container_path
    assert has_selector?("a", :text => 'Locations') if SETTINGS[:locations_enabled]
    assert has_selector?("a", :text => 'Organizations') if SETTINGS[:organizations_enabled]
  end
end
