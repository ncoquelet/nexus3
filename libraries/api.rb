module Nexus3
  # Interact with the Nexus3 API
  class Api
    def initialize(base_url, user, password)
      require 'httpclient'
      require 'json'

      @http_client = ::HTTPClient.new(base_url: base_url).tap do |client|
        # Authentication
        client.set_auth(base_url, user, password)
        client.force_basic_auth = true
        # Debugging
        client.debug_dev = STDOUT if ::Chef::Log.debug? || (ENV['HTTPCLIENT_LOG'] == 'stdout')
      end
    end

    attr_reader :http_client

    def request(method, path, ct = 'application/json', data = nil)
      data = case data
             when Hash, Array
               JSON.generate(data)
             else
               data
             end
      response = http_client.request(method, path, nil, data, 'Content-Type' => ct)

      raise "HTTP_STATUS=#{response.status_code} #{response.body}" unless response.ok?

      response.body
    rescue => e
      error_message = " with following error\n#{e.response.body}" if e.respond_to? 'response'
      raise "Nexus API: '#{e}' #{error_message}"
    end

    # Runs a specific script with parameters
    def run_script(scriptname, params)
      body = request(:post, "#{scriptname}/run", 'text/plain', params)
      JSON.parse(body)['result']
    end
  end
end
