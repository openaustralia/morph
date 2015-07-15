module SupportersHelper
  def number_in_cents_to_currency(number)
    number_to_currency(number.to_f / 100)
  end

  def plan_image_tag(plan, size='64x64')
    image_tag(plan.image_name, size: size, class: 'plan')
  end

  def plan_change_word(from_plan, to_plan)
    if from_plan.price.nil? || from_plan.price == to_plan.price
      "Become a #{to_plan.name}"
    elsif to_plan.price > from_plan.price
      "Upgrade"
    else
      "Downgrade"
    end
  end

  def plan_change_word_past_tense(from_plan, to_plan)
    if to_plan.price > from_plan.price
      "Upgraded"
    elsif to_plan.price < from_plan.price
      "Downgraded"
    else
      raise
    end
  end

  def joy_or_disappointment(from_plan, to_plan)
    case plan_change_word(from_plan, to_plan)
    when "Upgrade"
      "You're amazing!"
    when "Downgrade"
      "Thanks for continuing to be a supporter!"
    else
      raise
    end
  end

  def plan_reason(plan)
    case plan.stripe_plan_id
    when "morph_basic"
      "Support morph.io on a budget. Keep morph.io open and running and available to all"
    when "morph_standard"
      "Support continued development of the open-source software that powers morph.io"
    when "morph_advanced"
      "Rely on morph.io for your business or not-for-profit? Priority technical support to get you answers and fixes quickly"
    else
      raise
    end
  end

  def plan_recognition(plan)
    case plan.stripe_plan_id
    when "morph_basic"
      "#{content_tag :strong, 'Shows'} your support publicly".html_safe
    when "morph_standard", "morph_advanced"
      "#{content_tag :strong, 'Be featured'} on the landing page".html_safe
    else
      raise
    end
  end

  def plan_support(plan)
    case plan.stripe_plan_id
    when "morph_basic", "morph_standard"
      "#{content_tag :strong, 'Forum'} support".html_safe
    when "morph_advanced"
      "#{content_tag :strong, 'Priority'} technical support".html_safe
    else
      raise
    end
  end
end
