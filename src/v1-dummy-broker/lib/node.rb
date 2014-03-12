require 'securerandom'

module Dummy
  class Node < VCAP::Services::Base::Node

    attr_accessor :instances

    def initialize(opts)
      @instances = []
      super(opts)
    end

    def service_name
      'Dummy'
    end

    def provision(plan, credentials=nil, version=nil)
      service_id = SecureRandom.uuid
      instances << service_id

      {'name'=> service_id}
    end

    def announcement
      {
        'available_capacity' => 200,
        'capacity_unit' => capacity_unit
      }
    end
  end
end
