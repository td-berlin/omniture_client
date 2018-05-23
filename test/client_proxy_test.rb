require 'rubygems'
require 'minitest/autorun'
require 'yaml'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'omniture_client'

class ClientTest < Minitest::Test

  def setup
    config = YAML::load(File.open("test/config.yml"))
    @config = config["omniture"]

    @client = OmnitureClient::Client.new(
      @config["environment"],
      :wait_time     => @config["wait_time"],
      :auth_strategy => {
        :name     => :x_wsse,
        :username => @config["username"],
        :secret   => @config["secret"]
      },
      :http_options => {
        :http_proxyaddr => 'localhost',
        :http_proxyport => '8888'
      }
    )
  end

  def test_passing_proxy_parameters
    response = @client.send(:send_request, "Report.GetQueue")

    assert_equal('localhost', response.request.options[:http_proxyaddr])
    assert_equal('8888', response.request.options[:http_proxyport])
  end
end
