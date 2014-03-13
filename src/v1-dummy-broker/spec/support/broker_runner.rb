class BrokerRunner < ComponentRunner

  NUMBER_OF_SERVICES = 1

  def start(opts = {})
    @node_timeout = opts[:node_timeout] || 5

    sleep 10

    Bundler.with_clean_env do
      sh "bundle install >> #{tmp_dir}/log/bundle.out"
      write_config_files

      add_pid Process.spawn(
                { 'AUTHORIZATION_TOKEN' => ccng_auth_token},
                "bundle exec bin/start_gateway -c #{config_file_location}",
                log_options(:v1_dummy_broker)
      )
      add_pid Process.spawn(
        "bundle exec bin/start_node -c #{node_config_file_location}",
        log_options(:v1_dummy_node)
      )

      sleep 10

      wait_for_tcp_ready('V1 Dummy Broker Gateway', config_hash.fetch('port'))
      wait_for_gateway_to_register_all_services
      register_service_auth_tokens_with_cc
    end
  end

  private

  def register_service_auth_tokens_with_cc
    return if @service_auth_tokens_registered
    @service_auth_tokens_registered = true
    create_service_auth_token('v1-test', 'v1-test-token', 'pivotal-software')
  end

  def config_hash
    YAML.load_file(config_file_location)
  end

  def config_file_location
    "#{tmp_dir}/config/gateway_config.yml"
  end

  def node_config_file_location
    "#{tmp_dir}/config/node_config.yml"
  end

  def write_config_files
    config_file = asset('gateway_config.yml', BROKER_SPEC_ROOT)
    node_config_file = asset('node_config.yml', BROKER_SPEC_ROOT)
    FileUtils.cp(config_file, config_file_location)
    FileUtils.cp(node_config_file, node_config_file_location)
  end

  def wait_for_gateway_to_register_all_services
    registered_services_count = 0
    10.times do
      response = ccng_get('/v2/services')
      registered_services_count = response.fetch('resources').size
      return if registered_services_count == NUMBER_OF_SERVICES
      sleep 0.5
    end
    raise "V1 Dummy Broker never registered all of its services.
          Expected #{NUMBER_OF_SERVICES}, but #{registered_services_count} were registered"
  end
end
