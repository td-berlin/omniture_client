module OmnitureClient
  class Client

    DEFAULT_REPORT_WAIT_TIME       = 0.25
    DEFAULT_REPORT_TOTAL_WAIT_TIME = 120
    DEFAULT_LOG_IS_ACTIVE          = false

    ENVIRONMENTS = {
      :san_jose       => "https://api.omniture.com/admin/1.4/rest/",
      :dallas         => "https://api2.omniture.com/admin/1.4/rest/",
      :london         => "https://api3.omniture.com/admin/1.4/rest/",
      :san_jose_beta  => "https://beta-api.omniture.com/admin/1.4/rest/",
      :dallas_beta    => "https://beta-api2.omniture.com/admin/1.4/rest/",
      :sandbox        => "https://api-sbx1.omniture.com/admin/1.4/rest/"
    }

    attr_accessor :max_tries
    def initialize(environment, options={})
      @environment    = environment.is_a?(Symbol) ? ENVIRONMENTS[environment] : environment.to_s

      @wait_time      = options[:wait_time]     || DEFAULT_REPORT_WAIT_TIME
      @max_tries      = options[:max_tries]     || (DEFAULT_REPORT_TOTAL_WAIT_TIME / @wait_time).to_i
      @log            = options[:log]           || DEFAULT_LOG_IS_ACTIVE
      @auth_strategy  = options[:auth_strategy]
    end

    def request(method, parameters = {})
      response = send_request(method, parameters)

      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => pe
        response.body
      rescue Exception => e
        log(Logger::ERROR, "Error in request response:\n#{response.body}")
        raise "Error in request response:\n#{response.body}"
      end
    end

    def get_report_suites
      response = send_request("Company.GetReportSuites")
      JSON.parse(response.body)
    end

    def enqueue_report(report_description)
      response = send_request("Report.Queue", report_description)
      json     = JSON.parse(response.body)

      raise OmnitureClient::Exceptions::RequestInvalid.new(response.body) \
        if json["reportID"].nil?

      log(Logger::INFO, "Report with ID (" + json["reportID"].to_s + ") queued.")

      json
    end

    def get_queue
      response = send_request("Report.GetQueue")
      JSON.parse(response.body)
    end

    def get_enqueued_report(report_id)
      response_body = nil
      done          = false
      tries         = 0

      begin
        response      = send_request("Report.Get", {"reportID" => "#{report_id}"})
        response_body = JSON.parse(response.body)
        done          = true

        log(Logger::INFO, "Fetching report #{report_id} done.")
      rescue OmnitureClient::Exceptions::ReportNotReady => e
        log(Logger::INFO, "Report #{report_id} not ready. Retrying in #{@wait_time} sec - Error: #{e}...")

        tries += 1
        if tries >= @max_tries
          raise OmnitureClient::Exceptions::TriesExceeded.new({
            error_msg: "Tried to fetch data for report #{report_id} #{tries} times with "   \
                       "#{@wait_time} sec wait time between each request without success. " \
                       "Maximum tries configured: #{@max_tries}"
          }
        )
        end
        sleep @wait_time
      end while !done

      log(Logger::INFO, "Report with ID #{report_id} has finished processing.")

      response_body
    end

    def get_metrics(report_suite_id)
     response = send_request("Report.GetMetrics", {"reportSuiteID" => "#{report_suite_id}"})
     JSON.parse(response.body)
    end

    def get_elements(report_suite_id)
     response = send_request("Report.GetElements", {"reportSuiteID" => "#{report_suite_id}"})
     JSON.parse(response.body)
    end

    attr_writer :log

    def log?
      @log != false
    end

    def logger
      @logger ||= ::Logger.new(STDOUT)
    end

    def log_level
      @log_level ||= ::Logger::INFO
    end

    def log(*args)
      level = args.first.is_a?(Numeric) || args.first.is_a?(Symbol) ? args.shift : log_level
      logger.log(level, args.join(" ")) if log?
    end

    private

    def handle_errors(response)
      parsed = nil
      begin
        parsed = JSON.parse(response.body)
        if parsed["error"] == "report_not_ready"
          raise OmnitureClient::Exceptions::ReportNotReady.new(response.body)
        else
          raise OmnitureClient::Exceptions::RequestInvalid.new(response.body)
        end
      rescue JSON::ParserError => e
        if response.code == 404
          raise OmnitureClient::Exceptions::ReportNotFound.new(response.body)
        else
          raise e
        end
      end
    end

    def send_request(method, data = {})
      log(Logger::INFO, "Requesting #{method}...")

      response = HTTParty.post(
        @environment + "?method=#{method}",
        :body    => JSON.dump(data),
        :headers => request_headers
        )

      if response.code >= 400
        handle_errors(response)
      end

      log(Logger::INFO, "Server responded with response code #{response.code}.")

      response
    end

    def request_headers
      {}.tap do |headers|
        case @auth_strategy[:name]
        when :oauth
          headers["Authorization"] = "Bearer #{@auth_strategy[:access_token]}"
        when :x_wsse
          headers["X-WSSE"] = generate_x_wsse_headers
        else
          raise OmnitureClient::Exceptions::AuthStrategyNotSupported.new(@auth_strategy)
        end
      end
    end

    def generate_x_wsse_headers
      username = @auth_strategy[:username]
      secret   = @auth_strategy[:secret]
      nonce    = Digest::MD5.new.hexdigest(rand().to_s)
      created  = DateTime.now.strftime("%Y-%m-%dT%H:%M:%S%Z")
      combined = nonce + created + secret
      sha1     = Digest::SHA1.new.hexdigest(combined)
      password = Base64.encode64(sha1).to_s.chomp("\n")

      "UsernameToken Username=\"#{username}\", PasswordDigest=\"#{password}\", Nonce=\"#{nonce}\", Created=\"#{created}\""
    end
  end
end
