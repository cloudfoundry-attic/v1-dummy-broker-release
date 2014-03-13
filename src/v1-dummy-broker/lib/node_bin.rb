require 'erb'

module Dummy
  class NodeBin < VCAP::Services::Base::NodeBin

    def node_class
      Dummy::Node
    end

    def default_config_file
      template = File.expand_path('../../config/node_config.yml.erb', __FILE__)
      source = File.read(template)
      result = ERB.new(source).result
      path = File.expand_path('../../config/node_config.yml', __FILE__)
      File.open(path, 'w+') do |f|
        f.write(result)
      end

      Pathname.new(path)
    end

    def additional_config(options, config)
      options
    end

  end
end
