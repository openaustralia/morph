module SupportersHelper
  def number_in_cents_to_currency(number)
    number_to_currency(number.to_f / 100)
  end
end
