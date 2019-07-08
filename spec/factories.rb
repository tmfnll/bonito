# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'
require 'factory_bot'

FactoryBot.define do
  factory :moment, class: Bonito::Moment do
    transient do
      block { proc { true } }
    end
    initialize_with { new(&block) }
  end

  factory :serial, class: Bonito::SerialTimeline do
    transient do
      block { proc { true } }
    end
    duration { rand(14).days }
    initialize_with { new(duration, &block) }
  end

  factory :parallel, class: Bonito::ParallelTimeline do
  end
end
