require File.expand_path('../binding_http_handler', __FILE__)
require 'securerandom'

module Dummy
  class Node < VCAP::Services::Base::Node

    attr_accessor :instances, :bindings
    attr_reader :logger

    def initialize(opts)
      super(opts)
      @instances = {}
      @bindings = {}

      @host = opts[:ip_route]
      @port = VCAP.grab_ephemeral_port

      @logger.info("Starting server on #{@host}:#{@port}")
      EM.start_server @host, @port, BindingHttpHandler, self
    end

    def service_name
      'Dummy'
    end

    def provision(plan, credentials=nil, version=nil)
      service_id = SecureRandom.uuid
      large_number = SecureRandom.uuid
      instances[service_id] = large_number
      logger.info("Provisioning a new instance #{service_id} with large number: #{large_number}")

      {'name'=> service_id}
    end

    def announcement
      {
        'available_capacity' => 200,
        'capacity_unit' => capacity_unit
      }
    end

    def bind(name, bind_opts={})
      logger.info("Creating a binding instance #{name}")
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
        'secret' => @bindings[name]['secret']
      }
    end
  end
end
