require 'active_support/core_ext/numeric/time'
FactoryBot.define do
  factory :moment do
    block { proc { true } }
  end
  factory :window do
    duration { rand(14).days }
    block { proc { true } }
  end
end