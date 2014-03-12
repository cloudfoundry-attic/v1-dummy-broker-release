require 'spec_helper'

describe Dummy do
  it 'defines the Dummy namespace' do
    expect(defined?(Dummy)).to be_true
  end
end
