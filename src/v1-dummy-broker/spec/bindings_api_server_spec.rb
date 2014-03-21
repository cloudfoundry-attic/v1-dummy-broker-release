require 'spec_helper'

describe BindingsApiServer do
  let(:opts) do
    {
      logger: Logger.new(STDOUT),
      ip_route: local_ip,
      external_url: external_url,
      mbus: mbus,
      port: port
    }
  end

  let(:local_ip) { '127.0.0.1' }
  let(:external_url) { 'external_url.com' }
  let(:port) { 1234 }
  let(:registrar) { double('registrar') }
  let(:mbus) { 'nats://nats.nats' }
  let(:ephemeral_port) { 1234 }
  let(:instance_manager) { double(:instance_manager, instances: {}, bindings: {})}

  before do
    allow(EM).to receive(:start_server)
    allow(Cf::Registrar).to receive(:new).and_return(registrar)
    allow(registrar).to receive(:register_with_router)
    allow(VCAP).to receive(:grab_ephemeral_port).and_return(ephemeral_port)
  end

  describe 'start!' do
    let(:bindings_api) { BindingsApiServer.new(instance_manager, opts) }
    it 'starts an EM server with the BindingHttpHandler with the right host and port' do
      bindings_api.start!
      expect(EM).to have_received(:start_server).with(local_ip, ephemeral_port, BindingHttpHandler, instance_manager)
    end

    it 'registers the route of the EM server with the router' do
      bindings_api.start!
      expect(Cf::Registrar).to have_received(:new).with(
                                 message_bus_servers: [mbus],
                                 host: local_ip,
                                 port: ephemeral_port,
                                 uri: external_url
                               )
      expect(registrar).to have_received(:register_with_router)
    end
  end
end
