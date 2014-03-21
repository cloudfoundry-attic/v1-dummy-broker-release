require File.expand_path('../binding_http_handler', __FILE__)

class BindingsApiServer
  def initialize(instance_manager, opts)
    @instance_manager = instance_manager
    @host = opts[:ip_route]
    @port = opts[:port]
    @external_url = opts[:external_url]
    @mbus = opts[:mbus]
    @logger = opts[:logger]
  end

  def start!
    @logger.info("Starting server on #{@host}:#{@port}")
    EM.start_server @host, @port, BindingHttpHandler, @instance_manager

    @logger.info("Registering route #{@external_url} for #{@host}:#{@port}")
    Cf::Registrar.new(
      message_bus_servers: [@mbus],
      host: @host,
      port: @port,
      uri: @external_url,
    ).register_with_router
  end
end
