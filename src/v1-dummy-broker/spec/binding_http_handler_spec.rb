require 'spec_helper'

describe BindingHttpHandler do
  describe 'initialization' do
    it 'requires a Dummy::Node be passed to EM.start_server' do
      node_opts = {
        ip_route: 'localhost',
        logger: Logger.new(STDOUT)
      }

      EM.run do
        expect{ EM.start_server '0.0.0.0', nil, BindingHttpHandler }.to raise_error ArgumentError
        expect{ EM.start_server '0.0.0.0', nil, BindingHttpHandler, Dummy::Node.new(node_opts) }.not_to raise_error
        EM.stop
      end
    end
  end

  describe '#process_http_request' do
    let(:node) { Dummy::Node.new(ip_route: 'localhost', logger: Logger.new(STDOUT)) }
    let(:handler) { BindingHttpHandler.new(double('signature'), node) }
    let(:response) do
      res = EM::DelegatedHttpResponse.new(handler)
      allow(res).to receive(:send_response)
      allow(EM::DelegatedHttpResponse).to receive(:new).and_return(res)
      res
    end

    before do
      allow(EM).to receive(:start_server)
      @instance_name_1 = node.provision('free', nil, nil)['name']
      @instance_name_2 = node.provision('free', nil, nil)['name']
      @secret_1 = node.bind(@instance_name_1)['secret']
      @secret_2 = node.bind(@instance_name_2)['secret']
    end

    it 'returns the large number associated with the service instance' do
      auth_string = Base64.encode64("login:#{@secret_1}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_1}")

      allow(response).to receive(:content=)
      handler.process_http_request
      expect(response).to have_received(:content=).with(node.instances[@instance_name_1])
    end

    it 'returns different large numbers for different service instances' do
      auth_string = Base64.encode64("login:#{@secret_2}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_2}")

      allow(response).to receive(:content=)
      handler.process_http_request
      expect(response).to have_received(:content=).with(node.instances[@instance_name_2])
    end

    it 'returns a 404 when the service is not bound' do
      handler.instance_variable_set(:@http_request_uri, "/non-existent")

      allow(response).to receive(:status=)
      allow(response).to receive(:content=)

      handler.process_http_request

      expect(response).to have_received(:status=).with(404)
      expect(response).to have_received(:content=).with("")
    end

    it 'returns a 404 when the requester does not have the right credentials' do
      auth_string = Base64.encode64("login:#{@secret_2}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_1}")

      allow(response).to receive(:status=)
      allow(response).to receive(:content=)

      handler.process_http_request

      expect(response).to have_received(:status=).with(404)
      expect(response).to have_received(:content=).with("")
    end

    it 'returns the same large number and requires the same credentials when the service instance has two service bindings' do
      node.bind(@instance_name_1)

      auth_string = Base64.encode64("login:#{@secret_1}")
      handler.instance_variable_set(:@http_headers, "Authorization: Basic #{auth_string}")
      handler.instance_variable_set(:@http_request_uri, "/#{@instance_name_1}")

      allow(response).to receive(:content=)
      handler.process_http_request
      expect(response).to have_received(:content=).with(node.instances[@instance_name_1])
    end
  end
end
