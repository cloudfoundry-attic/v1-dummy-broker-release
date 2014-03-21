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
    if bindings[name]
      bindings[name]['num_bindings'] += 1
    else
      binding = {
        'secret' => SecureRandom.uuid,
        'num_bindings' => 1
      }

      bindings[name] = binding
    end

    {
      'host' => @host,
      'port' => @port,
      'login' => 'binding',
      'secret' => bindings[name]['secret'],
      'url' => "#{@external_url}/#{name}",
      'name' => name
    }
  end

  def unbind(credentials)
    name = credentials['name']
    return false unless binding = bindings[name]

    binding['num_bindings'] -= 1
    if binding['num_bindings'] == 0
      bindings.delete(name)
    end

    true
  end
end
