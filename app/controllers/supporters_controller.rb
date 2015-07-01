class SupportersController < ApplicationController
  before_filter :authenticate_user!

  def new
  end

  def create
    @price = params[:price]

    # TODO: Save customer to user
    customer = Stripe::Customer.create(
      email:       params[:stripeEmail],
      card:        params[:stripeToken],
      description: "Customer for @#{current_user.nickname}"
    )

    # TODO: Use subscriptions
    charge = Stripe::Charge.create(
      customer:    customer.id,
      amount:      @price,
      description: "morph.io basic supporter",
      currency:    "aud"
    )

  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to supporters_path
  end
end
