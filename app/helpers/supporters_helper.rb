module SupportersHelper
  def number_in_cents_to_currency(number)
    number_to_currency(number.to_f / 100)
  end

  def plan_image_tag(stripe_plan_id)
    image_tag("supporter-badge-#{stripe_plan_id}.png", size: '64x64')
  end

  def plan_change_word(from_plan, to_plan)
    if from_plan.price.nil? || from_plan.price == to_plan.price
      "Signup"
    elsif to_plan.price > from_plan.price
      "Upgrade"
    else
      "Downgrade"
    end
  end

  def plan_change_word_past_tense(from_plan, to_plan)
    word = plan_change_word(Plan.new(from_plan), Plan.new(to_plan))
    if word == "Signup"
      "Signed up"
    else
      word + "d"
    end
  end

  def joy_or_disappointment(from_plan, to_plan)
    case plan_change_word(Plan.new(from_plan), Plan.new(to_plan))
    when "Upgrade"
      "What a hero!"
    when "Downgrade"
      "Thanks for continuing to be a supporter!"
    else
      raise
    end
  end
end
