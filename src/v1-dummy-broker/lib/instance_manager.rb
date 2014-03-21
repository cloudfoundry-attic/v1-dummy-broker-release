class InstanceManager
  attr_accessor :instances, :bindings
  attr_reader :logger

  def initialize(opts)
    @instances = {}
    @bindings = {}

    @logger = opts[:logger]
    @host = opts[:ip_route]
    @external_url = opts[:external_url]
    @port = opts[:port]
    #
  end

  def provision
    service_id = SecureRandom.uuid
    large_number = SecureRandom.uuid
    instances[service_id] = large_number
    logger.info("Provisioning a new instance #{service_id} with large number: #{large_number}")

    {'name'=> service_id}
  end

  def bind(name)
    logger.info("Creating a binding for instance #{name}")
    unless @bindings[name]
      binding = {
        'secret' => SecureRandom.uuid
      }

      @bindings[name] = binding
    end

    {
      'host' => @host,
      'port' => @port,
      'login' => 'binding',
      'secret' => @bindings[name]['secret'],
      'url' => "#{@external_url}/#{name}"
    }
  end
end
