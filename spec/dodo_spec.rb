# frozen_string_literal: true

require 'dodo'
require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo do
  it 'has a version number' do
    expect(Dodo::VERSION).not_to be nil
  end

  it 'does something useful' do
   over 2.weeks do
      now do
        puts 'first moment'
      end
      over 3.days do
        now do
          puts 'second moment'
        end
      end
      now do
        puts 'third moment'
      end
    end
    window.eval starting: 2.weeks.ago
  end
end
