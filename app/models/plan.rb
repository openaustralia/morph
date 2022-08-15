# typed: strict
# frozen_string_literal: true

class Plan
  extend T::Sig

  sig { returns(T.nilable(String)) }
  attr_reader :stripe_plan_id

  PLAN_PRICES = T.let({ "morph_basic" => 14, "morph_standard" => 24, "morph_advanced" => 149 }.freeze, T::Hash[String, Integer])

  sig { params(stripe_plan_id: T.nilable(String)).void }
  def initialize(stripe_plan_id)
    @stripe_plan_id = stripe_plan_id
  end

  sig { returns(T::Array[String]) }
  def self.all_stripe_plan_ids
    %w[morph_basic morph_standard morph_advanced]
  end

  # Users of the top two plans are highlighted
  sig { returns(T::Array[Plan]) }
  def self.featured_plans
    all_plans.shift(2)
  end

  # All plans, highest first
  sig { returns(T::Array[Plan]) }
  def self.all_plans
    all_stripe_plan_ids.map { |id| Plan.new(id) }.reverse
  end

  sig { returns(String) }
  def image_name
    "supporter-badges/#{stripe_plan_id}.png"
  end

  sig { returns(String) }
  def name
    case stripe_plan_id
    when "morph_basic"
      "Supporter"
    when "morph_standard"
      "Hero"
    when "morph_advanced"
      "Partner"
    else
      raise
    end
  end

  sig { returns(T.nilable(Integer)) }
  def price
    s = stripe_plan_id
    PLAN_PRICES[s] if s
  end

  sig { returns(T.nilable(Integer)) }
  def price_in_cents
    p = price
    p * 100 if p
  end

  sig { params(other: Plan).returns(T::Boolean) }
  def ==(other)
    stripe_plan_id == other.stripe_plan_id
  end
end
