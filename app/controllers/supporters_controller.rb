# typed: strict
# frozen_string_literal: true

class SupportersController < ApplicationController
  extend T::Sig

  before_action :authenticate_user!, except: %i[new index]
  before_action :load_stripe_library

  sig { void }
  def index; end

  sig { void }
  def new
    authenticate_user! if params[:plan_id]
  end

  sig { void }
  def create
    authenticated_user = T.must(current_user)

    customer = Stripe::Customer.create(
      email: authenticated_user.email,
      card: params[:stripeToken],
      description: "morph.io user @#{authenticated_user.nickname}"
    )
    authenticated_user.update! stripe_customer_id: customer.id

    # TODO: Handle missing or incorrect plan
    subscription = customer.subscriptions.create plan: params[:plan_id]
    authenticated_user.update! stripe_plan_id: subscription[:plan][:id], stripe_subscription_id: subscription[:id]

    session[:new_supporter] = true
    redirect_to user_path(authenticated_user), notice: render_to_string(partial: "create_flash")
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to supporters_path
  end

  sig { void }
  def create_one_time
    authenticated_user = T.must(current_user)
    params_amount = T.cast(params[:amount], T.any(String, Numeric))

    customer = Stripe::Customer.create(
      email: authenticated_user.email,
      card: params[:stripeTokenOneTime],
      description: "morph.io user @#{authenticated_user.nickname}"
    )
    authenticated_user.update! stripe_customer_id: customer.id

    Stripe::Charge.create(
      customer: customer.id,
      amount: (params_amount.to_f * 100).round,
      description: "morph.io contribution",
      currency: "USD"
    )

    session[:new_supporter] = true
    redirect_to user_path(authenticated_user), notice: render_to_string(partial: "one_time_contribution_thanks")
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to supporters_path
  end

  sig { void }
  def update
    authenticated_user = T.must(current_user)
    plan_id = T.cast(params[:plan_id], String)

    @from_plan = T.let(authenticated_user.plan, T.nilable(Plan))
    @to_plan = T.let(Plan.new(plan_id), T.nilable(Plan))

    customer = Stripe::Customer.retrieve T.must(authenticated_user.stripe_customer_id)
    subscription = customer.subscriptions.retrieve authenticated_user.stripe_subscription_id
    subscription.plan = params[:plan_id]
    subscription.save
    authenticated_user.update! stripe_plan_id: subscription[:plan][:id]

    session[:new_supporter] = true
    redirect_to user_path(authenticated_user), notice: render_to_string(partial: "update_flash", locals: { from_plan: @from_plan, to_plan: @to_plan })
  end

  private

  sig { void }
  def load_stripe_library
    @load_stripe_library = T.let(true, T.nilable(T::Boolean))
  end
end
