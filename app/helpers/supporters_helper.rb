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
end
