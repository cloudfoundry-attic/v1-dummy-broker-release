require 'erb'

module Dummy
  class Gateway < VCAP::Services::Base::Gateway
    attr_reader :config

    def provisioner_class
      Provisioner
    end

    def default_config_file
      template = File.expand_path('../../config/gateway_config.yml.erb', __FILE__)
      source = File.read(template)
      result = ERB.new(source).result
      path = File.expand_path('../../config/config.yml', __FILE__)
      File.open(path, 'w+') do |f|
        f.write(result)
      end

      Pathname.new(path)
    end

    def load_config
      parse_config
      setup_vcap_logging
      setup_pid
      setup_async_job_config
    end

    def provisioner_config
      {
        :logger                => config[:logger],
        :index                 => config[:index],
        :ip_route              => config[:ip_route],
        :mbus                  => config[:mbus],
        :node_timeout          => config[:node_timeout] || 5,
        :z_interval            => config[:z_interval],
        :max_nats_payload      => config[:max_nats_payload],
        :additional_options    => additional_options,
        :status                => config[:status],
        :plan_management       => config[:plan_management],
        :service               => config[:service],
        :download_url_template => config[:download_url_template],
        :cc_api_version        => config[:cc_api_version] || "v1" ,
        :snapshot_db           => config[:resque]
      }
    end

  end
end
