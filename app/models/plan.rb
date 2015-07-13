class Plan
  attr_reader :stripe_plan_id

  def initialize(stripe_plan_id)
    @stripe_plan_id = stripe_plan_id
  end

  def self.all_stripe_plan_ids
    %w(morph_basic morph_standard morph_advanced)
  end

  def name
    case stripe_plan_id
    when 'morph_basic'
      'Supporter'
    when 'morph_standard'
      'Hero'
    when 'morph_advanced'
      'Champion'
    else
      fail
    end
  end

  def price
    case stripe_plan_id
    when 'morph_basic'
      14
    when 'morph_standard'
      24
    when 'morph_advanced'
      149
    end
  end

  def ==(plan)
    stripe_plan_id == plan.stripe_plan_id
  end
end
