# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'
require 'factory_bot'

FactoryBot.define do
  factory :moment, class: Dodo::Moment do
    transient do
      block { proc { true } }
    end
    initialize_with { new(&block) }
  end

  factory :window, class: Dodo::Window do
    transient do
      block { proc { true } }
    end
    duration { rand(14).days }
    initialize_with { new(duration, &block) }
  end

  factory :container, class: Dodo::Container do
  end
end
