require 'spec_helper'

describe BindingHttpHandler do
  describe 'initialization' do
    let(:registrar) { double('registrar') }

    it 'requires a InstanceManager be passed to EM.start_server' do
      opts = {
        ip_route: 'localhost',
        logger: Logger.new(STDOUT)
      }

      EM.run do
        expect{ EM.start_server '0.0.0.0', nil, BindingHttpHandler }.to raise_error ArgumentError
        expect{ EM.start_server '0.0.0.0', nil, BindingHttpHandler, InstanceManager.new(opts) }.not_to raise_error
        EM.stop
      end
    end
  end

  describe '#process_http_request' do
    let(:instance_manager) { InstanceManager.new(ip_route: 'localhost', logger: Logger.new(STDOUT),
                                 external_url: 'external_url.com',
                                 mbus: 'nats://nats.nats') }
    let(:handler) { BindingHttpHandler.new(double('sig'), instance_manager) }
    let(:response) do
      res = EM::DelegatedHttpResponse.new(handler)
      allow(res).to receive(:send_response)
      allow(EM::DelegatedHttpResponse).to receive(:new).and_return(res)
      res
    end

    before do
      allow(EM).to receive(:start_server)
      @instance_name_1 = instance_manager.provision['name']
      @instance_name_2 = instance_manager.provision['name']
      @secret_1 = instance_manager.bind(@instance_name_1)['secret']
      @secret_2 = instance_manager.bind(@instance_name_2)['secret']

      # Bind and unbind before request
      @unbound_instance_name = instance_manager.provision['name']
      @stale_credentials = instance_manager.bind(@unbound_instance_name)
      @stale_secret = @stale_credentials['secret']
      instance_manager.unbind(@stale_credentials)

    end

    it 'returns the large number associated with the service instance' do
      auth_string = Base64.encode64("login:#{@secret_1}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_1}")

      allow(response).to receive(:content=)
      handler.process_http_request
      expect(response).to have_received(:content=).with(instance_manager.instances[@instance_name_1])
    end

    it 'returns different large numbers for different service instances' do
      auth_string = Base64.encode64("login:#{@secret_2}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_2}")

      allow(response).to receive(:content=)
      handler.process_http_request
      expect(response).to have_received(:content=).with(instance_manager.instances[@instance_name_2])
    end

    it 'returns a 404 when the service is not bound' do
      handler.instance_variable_set(:@http_request_uri, "/non-existent")

      allow(response).to receive(:status=)
      allow(response).to receive(:content=)

      handler.process_http_request

      expect(response).to have_received(:status=).with(404)
      expect(response).to have_received(:content=).with("404 Not Found")
    end

    it 'returns a 401 when the requester does not provide any credentials' do
      handler.instance_variable_set(:@http_headers, "Other-Header: asdfasdfasdf")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_1}")

      allow(response).to receive(:status=)
      allow(response).to receive(:content=)

      handler.process_http_request

      expect(response).to have_received(:status=).with(401)
      expect(response).to have_received(:content=).with("401 Unauthorized")
    end

    it 'returns a 401 when the requester does not have the right credentials' do
      auth_string = Base64.encode64("login:#{@secret_2}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_1}")

      allow(response).to receive(:status=)
      allow(response).to receive(:content=)

      handler.process_http_request

      expect(response).to have_received(:status=).with(401)
      expect(response).to have_received(:content=).with("401 Unauthorized")
    end

    it 'returns a 403 if the instance is unbound' do
      auth_string = Base64.encode64("login:#{@stale_secret}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@unbound_instance_name}")

      allow(response).to receive(:status=)
      allow(response).to receive(:content=)

      handler.process_http_request

      expect(response).to have_received(:status=).with(403)
      expect(response).to have_received(:content=).with("403 Forbidden")
    end

    it 'returns a 400 if the request is malformed'

    it 'returns a 500 if an unhandled error occurs' do
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_1}")
      allow(instance_manager).to receive(:instances).and_raise(RuntimeError)

      allow(response).to receive(:status=)
      allow(response).to receive(:content=)

      handler.process_http_request

      expect(response).to have_received(:status=).with(500)
      expect(response).to have_received(:content=).with("500 Internal Server Error")
    end

    it 'returns the same large number and requires the same credentials when the service instance has two service bindings' do
      instance_manager.bind(@instance_name_1)

      auth_string = Base64.encode64("login:#{@secret_1}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_1}")

      allow(response).to receive(:content=)
      handler.process_http_request
      expect(response).to have_received(:content=).with(instance_manager.instances[@instance_name_1])
    end
  end
end
