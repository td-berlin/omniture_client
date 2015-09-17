# Omniture

This is a small library for accessing [Omnitures analytics API](https://marketing.adobe.com/developer/en_US/documentation/analytics-reporting-1-4/get-started).
Omniture's API is closed, you have to be a paying customer in order to access the data.

## initialization and authentication
The environment you'll use to connect to Omniture's API depends on which data center they're using to store your traffic data and will be one of:

* San Jose (https://api.omniture.com/admin/1.4/rest/)
* Dallas (https://api2.omniture.com/admin/1.4/rest/)
* London (https://api3.omniture.com/admin/1.4/rest/)
* San Jose Beta (https://beta-api.omniture.com/admin/1.4/rest/)
* Dallas (beta) (https://beta-api2.omniture.com/admin/1.4/rest/)
* Sandbox (https://api-sbx1.omniture.com/admin/1.4/rest/)


For authentication OmnitureClient requires you to provide one of the following authorization strategies:
* X-WSSE Headers
* oAuth

#### Using X-WSSE Headers
You will need a username and the corresponding secret.
Here's an example of initializing with X-WSSE authorization strategy:

    client = OmnitureClient::Client.new(
      :san_jose,
      :auth_strategy =>
      	:name => :x_wsse,
      	:username => "what the username",
      	:secret   => "what the secret"
      )


#### Using oAuth
You will need a valid oauth token.
Here's an example of initializing with oauth authorization strategy:

    client = OmnitureClient::Client.new(
      :san_jose,
      :auth_strategy =>
      	:name => :oauth,
      	:token => "what the token",
      )

## usage

The OmnitureClient::Client exposes the following methods:

* `request(method, parameters)` - more generic used to make any supported kind of request
* `get_report_suites` - get the available report suites for a company
* `enqueue_report(parameters)` - enqueue a report
* `get_queue` - get the reports which are still in the queue and not ready for fetching
* `get_enqueued_report(report_id)` - get the data for a previously enqueued report (if report is not ready it will retry as often as max_tries*wait_time)
* `get_metrics(report_suite_id)` - get all available metrics for a certain report suite

For reference, I'd recommend keeping [Omniture's Developer Portal](http://developer.omniture.com) open as you code.  It's not the easiest to navigate but most of what you need is there.

The response returned by either of these requests Ruby (parsed JSON).

## examples
    # Find all the company report suites
    client.get_report_suites

    # Enqueue a report
    client.enqueue_report({
      "reportDescription" => {
        "reportSuiteID" => "#{@config["report_suite_id"]}",
	"date" => "2014-07-01",
        "metrics" => [{"id" => "pageviews"}]
        }
    })

    # Fetch a report
    client.get_report(report_id)
