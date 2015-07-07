class SupportersController < ApplicationController
  before_filter :authenticate_user!

  def new
  end

  def create
    customer = Stripe::Customer.create(
      email:       params[:stripeEmail],
      card:        params[:stripeToken],
      description: "Customer for @#{current_user.nickname}"
    )
    current_user.update! stripe_customer_id: customer.id

    # TODO: Handle missing or incorrect plan
    subscription = customer.subscriptions.create plan: params[:plan_id]
    current_user.update! stripe_plan_id: subscription[:plan][:id], stripe_subscription_id: subscription[:id]

    redirect_to user_path(current_user), notice: render_to_string(partial: "create_flash")

  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to supporters_path
  end

  def update
    @from_plan, @to_plan = current_user.stripe_plan_id, params[:plan_id]

    customer = Stripe::Customer.retrieve current_user.stripe_customer_id
    subscription = customer.subscriptions.retrieve current_user.stripe_subscription_id
    subscription.plan = params[:plan_id]
    subscription.save
    current_user.update! stripe_plan_id: subscription[:plan][:id]

    redirect_to user_path(current_user), notice: render_to_string(partial: "update_flash")
  end
end
