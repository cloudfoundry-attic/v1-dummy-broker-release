module Dummy
  class Provisioner < VCAP::Services::Base::Provisioner

    def service_name
      'Dummy'
    end

  end
end
