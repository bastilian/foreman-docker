require 'test_plugin_helper'

class RegistryApiTest < ActiveSupport::TestCase
  let(:url) { 'http://dockerregistry.com:5000' }
  subject { Service::RegistryApi.new(url: url) }

  describe '#connection' do
    test 'returns a Docker::Connection' do
      assert_equal Docker::Connection, subject.connection.class
    end

    test 'the connection has the same url' do
      assert_equal url, subject.connection.url
    end

    context 'authentication is set' do
      let(:user) { 'username' }
      let(:password) { 'secretpassword' }

      test 'it sets the same user and password' do
        subject.user = user
        subject.password = password

        assert_equal user, subject.connection.options[:user]
        assert_equal password, subject.connection.options[:password]
      end
    end
  end

  describe '#get' do
    let(:path) { '/v1/search' }
    let(:json) { '{}' }

    test 'calls get on #connection' do
      subject.connection
        .expects(:get).at_least_once
        .returns(json)

      subject.get(path)
    end

    test 'returns a parsed json' do
      subject.connection.stubs(:get).returns(json)
      assert_equal JSON.parse(json), subject.get(path)
    end

    # Docker::Connection is used and meant for the Docker,
    # not the Registry API therefore it is required
    # to override the path via options
    test 'sets the path as an option not param for Docker::Connection#get' do
      subject.connection.stubs(:get) do |path_param, _, options|
        refute_equal path, path_param
        assert_equal path, options[:path]
      end.returns(json)

      subject.get(path)
    end

    # Docker Hub will return a 503 when a 'Host' header includes a port.
    # Omitting default ports (an Excon option) solves the issue
    test 'sets omit_default_port to true' do
      subject.connection.stubs(:get) do |_, _, options|
        assert options[:omit_default_port]
      end.returns(json)

      subject.get(path)
    end
  end

  describe '#search' do
    let(:path) { '/v1/search' }
    let(:query) { 'centos' }

    test "calls #get with path and query" do
      subject.expects(:get).with(path, {q: query}).once do |path_param, params|
        assert_equal path, path_param
        assert_equal query, params[:q]
      end.returns({})

      subject.search(query)
    end

    test "falls back to #catalog if #get fails" do
      subject.expects(:catalog).with(query).once

      subject.expects(:get).with(path, {q: query}).once
        .raises('Error')

      subject.search(query)
    end
  end

  describe '#catalog' do
    let(:path) { '/v2/_catalog' }
    let(:query) { 'centos' }
    let(:catalog) { { 'repositories' => ['centos', 'fedora'] } }

    setup do
      subject.stubs(:get).returns(catalog)
    end

    test "calls #get with path" do
      subject.expects(:get).with(path)
        .returns(catalog)

      subject.catalog(query)
    end

    test 'returns {"name" => value} pairs' do
      result = subject.catalog(query)
      assert_equal({ "name" => query }, result.first)
    end

    test 'only give back matching results' do
      result = subject.catalog('fedora')
      assert_match(/^fedora/, result.first['name'])
    end
  end

  describe '#tags' do
    let(:query) { 'alpine' }
    let(:path) { "/v1/repositories/#{query}/tags" }

    test "calls #get with path" do
      subject.expects(:get).with(path).once
      subject.tags(query)
    end

    test "falls back to #tags_v2 if #get fails" do
      subject.expects(:get).with(path).once
        .raises('Error')

      subject.expects(:tags_v2).with(query).once
      subject.tags(query)
    end
  end

  describe '#tags_v2' do
    let(:query) { 'debian' }
    let(:path) { "/v2/#{query}/tags/list" }
    let(:tags) { { 'tags' => ['jessy', 'woody'] } }

    test 'calls #get with path' do
      subject.expects(:get).with(path).once
        .returns(tags)
      subject.tags_v2(query)
    end

    test 'returns {"name" => value } pairs ' do
      subject.stubs(:get).returns(tags)
      result = subject.tags_v2(query)
      assert_equal tags['tags'].first, result.first['name']
    end
  end

  describe '.docker_hub' do
    subject { Service::RegistryApi }

    test 'returns an instance for Docker Hub' do
      result = subject.docker_hub
      assert_equal Service::RegistryApi::DOCKER_HUB, result.url
    end
  end
end
