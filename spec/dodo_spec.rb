require "dodo"

RSpec.describe Dodo do
  it "has a version number" do
    expect(Dodo::VERSION).not_to be nil
  end

  it "does something useful" do
    window = Dodo::TimeWarp::Window.new 20 do
      now do
        puts "first moment"
      end
      over 3 do
        now do
          puts "second moment"
        end
      end
      now do
        puts "third moment"
      end
    end
    window.schedule 0
  end


end
