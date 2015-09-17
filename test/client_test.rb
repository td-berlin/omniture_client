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
      }
    )
  end

  def test_request_wo_params
    response = @client.request("Report.GetQueue")

    assert_instance_of Array, response, "returned object is not an array."
  end

  def test_request_w_params
    response = @client.request("Report.Queue", {
      "reportDescription" => {
        "reportSuiteID" => "#{@config["report_suite_id"]}",
        "date" => "2014-07-01",
        "metrics" => [{"id" => "pageviews"}]
    }})

    assert_instance_of Hash, response, "Returned object is not a hash."
    assert(response.has_key?("reportID"), "Returned hash has no data!")
  end

  def test_get_report_suites
    response = @client.get_report_suites

    assert_instance_of Hash, response, "Returned object is not a hash."
    assert(response.has_key?("report_suites"), "Returned hash does not contain any report suites.")
  end

  def test_enqueue_report
    response = @client.enqueue_report({
      "reportDescription" => {
        "reportSuiteID" => "#{@config["report_suite_id"]}",
        "date" => "2014-07-01",
        "metrics" => [{"id" => "pageviews"}]
    }})

    assert_instance_of Hash, response, "Returned object is not a hash."
    assert(response.has_key?("reportID"), "Returned hash has no data!")
  end

  def test_enqueue_report_with_invalid_metric_raises
    assert_raises OmnitureClient::Exceptions::RequestInvalid do
      response = @client.enqueue_report({
        "reportDescription" => {
          "reportSuiteID" => "#{@config["report_suite_id"]}",
          "date" => "2014-07-01",
          "metrics" => [{"id" => "INVALID_METRIXXXX"}]
      }})
    end
  end

  def test_enqueue_report_with_invalid_metric_raises
    assert_raises OmnitureClient::Exceptions::RequestInvalid do
      response = @client.enqueue_report({
        "reportDescription" => {
          "reportSuiteID" => "INVALID_REPORT_SUITE_ID",
          "date" => "2014-07-01",
          "metrics" => [{"id" => "pageVIews"}]
      }})
    end
  end

  def test_get_queue
    response = @client.get_queue
    assert_instance_of Array, response, "Returned object is not an array."
  end

  def test_get_enqueued_report
    response = @client.enqueue_report({
      "reportDescription" => {
        "reportSuiteID" => "#{@config["report_suite_id"]}",
        "date" => "2014-07-01",
        "metrics" => [{"id" => "pageviews"}]
    }})
    report_id = response["reportID"]

    response = @client.get_enqueued_report(report_id)

    assert_instance_of Hash, response, "Returned object is not a hash."
    assert(response["report"].has_key?("data"), "Returned hash has no data!")
  end

  def test_get_unfinished_enqueued_report_raises
    response = @client.enqueue_report({
      "reportDescription" => {
        "reportSuiteID" => "#{@config["report_suite_id"]}",
        "dateFrom" => "2011-07-01",
        "dateTo" => "2014-07-07",
        "metrics" => [{"id" => "pageviews"}]
    }})
    report_id = response["reportID"]

    assert_raises OmnitureClient::Exceptions::TriesExceeded do
      @client.max_tries = 1
      response = @client.get_enqueued_report(report_id)
    end
  end

  def test_get_metrics
    response = @client.get_metrics(@config["report_suite_id"])

    assert_instance_of Array, response, "Returned object is not a hash."
    assert(response.first.has_key?("id"), "Returned array has no metrics!")
  end
end
