require 'rspec'
require 'active_support/core_ext/numeric/time'
describe Dodo::ContainerEnumerator do

  let(:moments) { build_list :moment }
  let(:offset_moments) do
    moments.map { |moment| OffsetHappening.new(moment, rand(10).days) }
  end

  let(:more_moments) { build_list :moment }
  let(:more_offset_moments) do
    more_moments.map { |moment| OffsetHappening.new(moment, rand(10).days) }
  end

  let(:window) { build :window }
  let(:another_window) { build :window }

  let(:window_enumerator) { Dodo::WindowEnumerator.new window }
  let(:another_window_enumerator) { Dodo::WindowEnumerator.new another_window }

  before do
    allow(:window_enumerator).to receive(:each).and_return(offset_moments)
    allow(:another_window_enumerator).to receive(:each).and_return(more_offset_moments)

    allow(:window).to receive(:enum).and_return(window_enumerator)
    allow(:another_window).to receive(:enum).and_return(another_window_enumerator)
  end

  let(:container)

end