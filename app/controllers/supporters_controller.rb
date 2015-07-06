class SupportersController < ApplicationController
  before_filter :authenticate_user!

  def new
  end

  def create
    # Create or retrieve the Stripe customer
    if current_user.stripe_customer_id
      # TODO: Handle missing or deleted customer
      customer = Stripe::Customer.retrieve current_user.stripe_customer_id
    else
      customer = Stripe::Customer.create(
        email:       params[:stripeEmail],
        card:        params[:stripeToken],
        description: "Customer for @#{current_user.nickname}"
      )
      current_user.update! stripe_customer_id: customer.id
    end

    # TODO: Handle missing or incorrect plan
    subscription = customer.subscriptions.create plan: params[:plan_id]
    current_user.update! stripe_plan_id: subscription[:plan][:id], stripe_subscription_id: subscription[:id]
    @price = subscription[:plan][:amount]

  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to supporters_path
  end

  def update
    customer = Stripe::Customer.retrieve current_user.stripe_customer_id
    subscription = customer.subscriptions.retrieve current_user.stripe_subscription_id
    subscription.plan = params[:plan_id]
    subscription.save
    current_user.update! stripe_plan_id: subscription[:plan][:id]
  end
end
