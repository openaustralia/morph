module SupportersHelper
  def number_in_cents_to_currency(number)
    number_to_currency(number.to_f / 100)
  end

  def human_plan_name(stripe_plan_id)
    case stripe_plan_id
    when 'morph_basic'
      'Basic Supporter'
    when 'morph_standard'
      'Standard Supporter'
    when 'morph_advanced'
      'Advanced Supporter'
    end
  end

  def plan_image_tag(stripe_plan_id)
    image_tag("supporter-badge-#{stripe_plan_id}.png", size: '64x64')
  end

  # TODO: This sort of information really belongs in a plan model
  def plan_price(stripe_plan_id)
    case stripe_plan_id
    when 'morph_basic'
      14
    when 'morph_standard'
      24
    when 'morph_advanced'
      149
    end
  end

  def plan_change_word(from_plan, to_plan)
    if (from_plan == "morph_basic" && to_plan == "morph_standard") ||
       (from_plan == "morph_basic" && to_plan == "morph_advanced") ||
       (from_plan == "morph_standard" && to_plan == "morph_advanced")
      "Upgrade"
    elsif (from_plan == "morph_standard" && to_plan == "morph_basic") ||
          (from_plan == "morph_advanced" && to_plan == "morph_basic") ||
          (from_plan == "morph_advanced" && to_plan == "morph_standard")
      "Downgrade"
    else
      "Signup"
    end
  end

  def plan_change_word_past_tense(from_plan, to_plan)
    word = plan_change_word(from_plan, to_plan)
    if word == "Signup"
      "Signed up"
    else
      word + "d"
    end
  end

  def joy_or_disappointment(from_plan, to_plan)
    case plan_change_word(from_plan, to_plan)
    when "Upgrade"
      "What a hero!"
    when "Downgrade"
      "Thanks for continuing to be a supporter!"
    else
      raise
    end
  end
end
