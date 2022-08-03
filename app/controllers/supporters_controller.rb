# frozen_string_literal: true

class SupportersController < ApplicationController
  before_action :authenticate_user!, except: %i[new index]
  before_action :load_stripe_library

  def index; end

  def new
    authenticate_user! if params[:plan_id]
  end

  def create
    customer = Stripe::Customer.create(
      email: current_user.email,
      card: params[:stripeToken],
      description: "morph.io user @#{current_user.nickname}"
    )
    current_user.update! stripe_customer_id: customer.id

    # TODO: Handle missing or incorrect plan
    subscription = customer.subscriptions.create plan: params[:plan_id]
    current_user.update! stripe_plan_id: subscription[:plan][:id], stripe_subscription_id: subscription[:id]

    session[:new_supporter] = true
    redirect_to user_path(current_user), notice: render_to_string(partial: "create_flash")
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to supporters_path
  end

  def create_one_time
    customer = Stripe::Customer.create(
      email: current_user.email,
      card: params[:stripeTokenOneTime],
      description: "morph.io user @#{current_user.nickname}"
    )
    current_user.update! stripe_customer_id: customer.id

    Stripe::Charge.create(
      customer: customer.id,
      amount: (params[:amount].to_f * 100).round,
      description: "morph.io contribution",
      currency: "USD"
    )

    session[:new_supporter] = true
    redirect_to user_path(current_user), notice: render_to_string(partial: "one_time_contribution_thanks")
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to supporters_path
  end

  def update
    @from_plan = current_user.plan
    @to_plan = Plan.new(params[:plan_id])

    customer = Stripe::Customer.retrieve current_user.stripe_customer_id
    subscription = customer.subscriptions.retrieve current_user.stripe_subscription_id
    subscription.plan = params[:plan_id]
    subscription.save
    current_user.update! stripe_plan_id: subscription[:plan][:id]

    session[:new_supporter] = true
    redirect_to user_path(current_user), notice: render_to_string(partial: "update_flash")
  end

  private

  def load_stripe_library
    @load_stripe_library = true
  end
end
