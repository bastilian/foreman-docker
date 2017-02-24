require 'test_plugin_helper'

module ForemanDocker
  class DockerTest < ActiveSupport::TestCase
    should allow_value('a@b.com').for(:email)
    should allow_value('').for(:email)
    should_not allow_value('abcb.com').for(:email)
    should_not allow_value('a').for(:email)

    subject { FactoryGirl.create(:docker_cr) }

    describe '#tags_for_local_image' do
      let(:image) { Hash.new }
      let(:tags) { ['centos:latest', 'centos:5.1'] }
      let(:tag_names) { tags.map { |tag| tag.split(':').last }}

      setup do
        image.stubs(:info).returns({ 'RepoTags' => tags })
      end

      test 'returns tag names' do
        image_tags = subject.tags_for_local_image(image)
        assert_equal tag_names, image_tags
      end

      test 'allows filtering' do
        image_tags = subject.tags_for_local_image(image, '5')
        assert_equal ['5.1'], image_tags
      end
    end
  end
end
