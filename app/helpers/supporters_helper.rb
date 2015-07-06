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

  def signup_button_label(amount)
    if !current_user.supporter?
      "Signup"
    elsif amount > plan_prices[current_user.stripe_plan_id.to_sym]
      "Upgrade"
    elsif amount < plan_prices[current_user.stripe_plan_id.to_sym]
      "Downgrade"
    end
  end

  private

  # TODO: Remove this hardcoded pricing
  def plan_prices
    {basic: 1400, standard: 2900, advanced: 14900}
  end
end
