require 'test_plugin_helper'

class ImageSearchControllerTest < ActionController::TestCase
  let(:compute_resource) { FactoryGirl.create(:docker_cr) }

  setup do
    @container = FactoryGirl.create(:docker_cr)
  end

  describe '#auto_complete_repository_name' do
    let(:term) { 'centos' }
    let(:exists) { true }

    test 'returns true if the image exists' do
      ForemanDocker::ImageSearch.any_instance.expects(:available?).with(term)
        .returns(exists)
      xhr :get, :auto_complete_repository_name,
        { search: term, id: compute_resource.id }, set_session_user
      assert_equal exists.to_s, response.body
    end

    test 'returns false if the image does not exist' do
      exists = false
      ForemanDocker::ImageSearch.any_instance.expects(:available?).with(term)
        .returns(exists)

      xhr :get, :auto_complete_repository_name,
        { search: term, id: compute_resource.id }, set_session_user
      assert_equal exists.to_s, response.body
    end
  end

  describe '#auto_complete_image_tag' do
    let(:tags) { ['latest', '5', '4.3'] }

    test 'returns an array of { label:, value: } hashes' do
      ForemanDocker::ImageSearch.any_instance.expects(:search)
        .with({ term: 'test', tags: true })
        .returns(tags)
      xhr :get, :auto_complete_image_tag, { search: "test", id: @container.id }, set_session_user
      assert_equal tags.first, JSON.parse(response.body).first['value']
    end
  end

  [Docker::Error::DockerError, Excon::Errors::Error, Errno::ECONNREFUSED].each do |error|
    test 'auto_complete_repository_name catches exceptions on network errors' do
      ForemanDocker::ImageSearch.any_instance.expects(:available?)
        .raises(error)
      xhr :get, :auto_complete_repository_name, { :search => "test", :id => @container.id },
          set_session_user
      assert_response_is_expected
    end

    test 'auto_complete_image_tag catch exceptions on network errors' do
      ForemanDocker::ImageSearch.any_instance.expects(:search).raises(error)
      xhr :get, :auto_complete_image_tag, { :search => "test", :id => @container.id }, set_session_user
      assert_response_is_expected
    end

    test 'search_repository catch exceptions on network errors' do
      ForemanDocker::ImageSearch.any_instance.expects(:search).raises(error)
      xhr :get, :search_repository, { :search => "test", :id => @container.id }, set_session_user
      assert_response_is_expected
    end
  end

  test "centos 7 search responses are handled correctly" do
    repository = "registry-fancycorp.rhcloud.com/fancydb-rhel7/fancydb"
    repo_full_name = "redhat.com: #{repository}"
    request.env["HTTP_ACCEPT"] = "application/javascript"
    expected = [{  "description" => "Really fancy database app...",
                   "is_official" => true,
                   "is_trusted" => true,
                   "name" =>  repo_full_name,
                   "star_count" => 0
                }]
    ForemanDocker::ImageSearch.any_instance.expects(:search).returns(expected).at_least_once
    xhr :get, :search_repository, { :search => "centos", :id => @container.id }, set_session_user
    assert_response :success
    refute response.body.include?(repo_full_name)
    assert response.body.include?(repository)
  end

  test "fedora search responses are handled correctly" do
    repository = "registry-fancycorp.rhcloud.com/fancydb-rhel7/fancydb"
    repo_full_name = repository
    request.env["HTTP_ACCEPT"] = "application/javascript"
    expected = [{ "description" => "Really fancy database app...",
                  "is_official" => true,
                  "is_trusted" => true,
                  "name" =>  repo_full_name,
                  "star_count" => 0
                }]
    ForemanDocker::ImageSearch.any_instance.expects(:search).returns(expected).at_least_once
    xhr :get, :search_repository, { :search => "centos", :id => @container.id }, set_session_user
    assert_response :success
    assert response.body.include?(repo_full_name)
    assert response.body.include?(repository)
  end

  def assert_response_is_expected
    assert_response :error
    assert response.body.include?('An error occured during repository search:')
  end
end
