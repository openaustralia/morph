module SupportersHelper
  def number_in_cents_to_currency(number)
    number_to_currency(number.to_f / 100)
  end

  def human_plan_name(stripe_plan_id)
    case stripe_plan_id
    when 'basic'
      'Basic Supporter'
    when 'standard'
      'Standard Supporter'
    when 'advanced'
      'Advanced Supporter'
    end
  end

  def plan_image_tag(stripe_plan_id)
    image_tag("supporter-badge-#{stripe_plan_id}.png", size: '64x64')
  end

  def plan_change_word(from_plan, to_plan)
    if (from_plan == "basic" && to_plan == "standard") ||
       (from_plan == "basic" && to_plan == "advanced") ||
       (from_plan == "standard" && to_plan == "advanced")
      "Upgrade"
    elsif (from_plan == "standard" && to_plan == "basic") ||
          (from_plan == "advanced" && to_plan == "basic") ||
          (from_plan == "advanced" && to_plan == "standard")
      "Downgrade"
    else
      "Signup"
    end
  end

  def joy_or_disappointment(from_plan, to_plan)
    change_direction = plan_change_word(from_plan, to_plan).downcase

    case change_direction
    when "upgrade"
      "What a hero!"
    when "downgrade"
      "Thanks for continuing to be a supporter!"
    else
      raise
    end
  end
end
