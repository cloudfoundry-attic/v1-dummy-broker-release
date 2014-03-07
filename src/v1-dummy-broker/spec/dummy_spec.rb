require File.expand_path('../../lib/dummy', __FILE__)

describe Dummy do
  it 'defines the Dummy namespace' do
    expect(defined?(Dummy)).to be_true
  end
end
