require File.expand_path('../bindings_api_server', __FILE__)
require File.expand_path('../instance_manager', __FILE__)
require 'cf-registrar'
require 'securerandom'

module Dummy
  class Node < VCAP::Services::Base::Node

    attr_reader :instance_manager

    def initialize(opts)
      super(opts)
      port = VCAP.grab_ephemeral_port
      opts = opts.merge(logger: @logger, port: port)

      @instance_manager = InstanceManager.new(opts)
      @bindings_api = BindingsApiServer.new(@instance_manager, opts)
      @bindings_api.start!
    end

    def service_name
      'Dummy'
    end

    def announcement
      {
        'available_capacity' => 200,
        'capacity_unit' => capacity_unit
      }
    end

    def provision(plan, credentials=nil, version=nil)
      @instance_manager.provision
    end

    def bind(name, bind_opts={}, credentials=nil)
      @instance_manager.bind(name)
    end

    def unbind(credentials)
      @instance_manager.unbind(credentials)
    end

    def unprovision(name, bindings=nil)
      @instance_manager.unprovision(name)
    end

    def instances
      @instance_manager.instances
    end

    def bindings
      @instance_manager.bindings
    end
  end
end
