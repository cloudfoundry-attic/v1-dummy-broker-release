require 'evma_httpserver'
require 'base64'

class BindingHttpHandler < EM::Connection
  def initialize(instance_manager)
    @instance_manager = instance_manager
    @logger = instance_manager.logger
    super()
  end

  include EM::HttpServer

  def process_http_request
    instance_name = parse_instance_name_from_request_uri
    @logger.info("Request made for instance #{instance_name}")
    return send_http_resp(404, "Not Found") unless @instance_manager.instances[instance_name]

    return send_http_resp(403, "Forbidden") unless @instance_manager.bindings[instance_name]

    headers = parse_headers
    secret = parse_basic_auth_params(headers)
    @logger.info("Request included credentials #{secret}")
    return send_http_resp(401, "Unauthorized") unless secret && @instance_manager.bindings[instance_name]['secret'] == secret

    large_number = @instance_manager.instances[instance_name]
    @logger.info("Rendering 200 with body: #{large_number}")
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = large_number
    response.send_response
  rescue => e
    @logger.info("Unhandled error: #{e.message}")
    send_http_resp(500, "Internal Server Error")
  end

  private

  def send_http_resp(code, content)
    @logger.info("Rendering #{code}")
    response = EM::DelegatedHttpResponse.new(self)
    response.status = code
    response.content_type 'text/html'
    response.content = "#{code} #{content}"
    response.send_response
  end

  def parse_instance_name_from_request_uri
    @http_request_uri.split('/').last
  end

  def parse_headers
    headers_array = @http_headers.split("\u0000")
    headers = {}
    headers_array.each do |header_string|
      split_index = header_string.index(":")
      key = header_string[0..(split_index-1)]
      value = header_string[(split_index+1)..-1].strip
      headers[key] = value
    end
    headers
  end

  def parse_basic_auth_params(headers)
    auth_header = headers["Authorization"]
    return nil unless auth_header

    base64 = auth_header.gsub("Basic ", "")
    _, secret = Base64.decode64(base64).split(":")
    secret
  end
end
