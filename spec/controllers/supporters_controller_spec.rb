# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe SupportersController, type: :controller do
  let(:user) { create(:user, email: "test@example.com") }
  let(:stripe_customer) { double("Stripe::Customer", id: "cus_test123") }
  let(:stripe_subscription) do
    double("Stripe::Subscription", id: "sub_test123").tap do |sub|
      allow(sub).to receive(:[]).with(:plan).and_return(id: "plan_basic")
      allow(sub).to receive(:[]).with(:id).and_return("sub_test123")
      allow(sub).to receive(:plan=)
      allow(sub).to receive(:save)
    end
  end

  before do
    # Stub only external Stripe API calls
    allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
    allow(Stripe::Customer).to receive(:retrieve).and_return(stripe_customer)
    allow(stripe_customer).to receive(:subscriptions).and_return(double(create: stripe_subscription, retrieve: stripe_subscription))
    allow(Stripe::Charge).to receive(:create).and_return(double("Stripe::Charge"))
  end

  describe "GET #index" do
    it "returns http success without authentication" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "loads the Stripe library" do
      get :index
      expect(assigns(:load_stripe_library)).to be(true)
    end
  end

  describe "GET #new" do
    context "without plan_id parameter" do
      it "returns http success without authentication" do
        get :new
        expect(response).to have_http_status(:success)
      end
    end

    context "with plan_id parameter" do
      it "requires authentication" do
        get :new, params: { plan_id: "plan_basic" }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "allows access when authenticated" do
        sign_in user
        get :new, params: { plan_id: "plan_basic" }
        expect(response).to have_http_status(:success)
      end
    end

    it "loads the Stripe library" do
      get :new
      expect(assigns(:load_stripe_library)).to be(true)
    end
  end

  describe "POST #create" do
    before { sign_in user }

    context "with valid Stripe token" do
      let(:valid_params) do
        {
          stripeToken: "tok_test123",
          plan_id: "plan_basic"
        }
      end

      it "creates a Stripe customer" do
        allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
        post :create, params: valid_params
        expect(Stripe::Customer).to have_received(:create).with(
          email: user.email,
          card: "tok_test123",
          description: "morph.io user @#{user.nickname}"
        )
      end

      it "updates user with stripe_customer_id" do
        post :create, params: valid_params
        expect(user.reload.stripe_customer_id).to eq("cus_test123")
      end

      it "creates a subscription with the specified plan" do
        subscriptions = double
        allow(stripe_customer).to receive(:subscriptions).and_return(subscriptions)
        allow(subscriptions).to receive(:create).and_return(stripe_subscription)
        post :create, params: valid_params
        expect(subscriptions).to have_received(:create).with(plan: "plan_basic")
      end

      it "updates user with stripe_plan_id and stripe_subscription_id" do
        post :create, params: valid_params
        user.reload
        expect(user.stripe_plan_id).to eq("plan_basic")
        expect(user.stripe_subscription_id).to eq("sub_test123")
      end

      it "sets new_supporter session flag" do
        post :create, params: valid_params
        expect(session[:new_supporter]).to be(true)
      end

      it "redirects to user profile" do
        post :create, params: valid_params
        expect(response).to redirect_to(user_path(user))
      end
    end

    context "when Stripe raises a CardError" do
      before do
        allow(Stripe::Customer).to receive(:create).and_raise(Stripe::CardError.new("Card declined", nil, code: "card_declined"))
      end

      it "sets flash error message" do
        post :create, params: { stripeToken: "tok_invalid", plan_id: "plan_basic" }
        expect(flash[:error]).to eq("Card declined")
      end

      it "redirects to supporters path" do
        post :create, params: { stripeToken: "tok_invalid", plan_id: "plan_basic" }
        expect(response).to redirect_to(supporters_path)
      end
    end

    it "requires authentication" do
      sign_out user
      post :create, params: { stripeToken: "tok_test123", plan_id: "plan_basic" }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST #create_one_time" do
    before { sign_in user }

    context "with valid parameters" do
      let(:valid_params) do
        {
          stripeTokenOneTime: "tok_test123",
          amount: "25.50"
        }
      end

      it "creates a Stripe customer" do
        allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
        post :create_one_time, params: valid_params
        expect(Stripe::Customer).to have_received(:create).with(
          email: user.email,
          card: "tok_test123",
          description: "morph.io user @#{user.nickname}"
        )
      end

      it "updates user with stripe_customer_id" do
        post :create_one_time, params: valid_params
        expect(user.reload.stripe_customer_id).to eq("cus_test123")
      end

      it "creates a Stripe charge with correct amount" do
        allow(Stripe::Charge).to receive(:create).and_return(double("Stripe::Charge"))
        post :create_one_time, params: valid_params
        expect(Stripe::Charge).to have_received(:create).with(
          customer: "cus_test123",
          amount: 2550, # 25.50 * 100
          description: "morph.io contribution",
          currency: "USD"
        )
      end

      it "handles integer amounts" do
        allow(Stripe::Charge).to receive(:create).and_return(double("Stripe::Charge"))
        post :create_one_time, params: { stripeTokenOneTime: "tok_test123", amount: 25 }
        expect(Stripe::Charge).to have_received(:create).with(
          hash_including(amount: 2500) # 25 * 100
        )
      end

      it "handles string amounts with decimals" do
        allow(Stripe::Charge).to receive(:create).and_return(double("Stripe::Charge"))
        post :create_one_time, params: { stripeTokenOneTime: "tok_test123", amount: "10.99" }
        expect(Stripe::Charge).to have_received(:create).with(
          hash_including(amount: 1099) # 10.99 * 100
        )
      end

      it "sets new_supporter session flag" do
        post :create_one_time, params: valid_params
        expect(session[:new_supporter]).to be(true)
      end

      it "redirects to user profile" do
        post :create_one_time, params: valid_params
        expect(response).to redirect_to(user_path(user))
      end
    end

    context "when Stripe raises a CardError" do
      before do
        allow(Stripe::Customer).to receive(:create).and_raise(Stripe::CardError.new("Card declined", nil, code: "card_declined"))
      end

      it "sets flash error message" do
        post :create_one_time, params: { stripeTokenOneTime: "tok_invalid", amount: "10" }
        expect(flash[:error]).to eq("Card declined")
      end

      it "redirects to supporters path" do
        post :create_one_time, params: { stripeTokenOneTime: "tok_invalid", amount: "10" }
        expect(response).to redirect_to(supporters_path)
      end
    end

    it "requires authentication" do
      sign_out user
      post :create_one_time, params: { stripeTokenOneTime: "tok_test123", amount: "10" }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH #update" do
    before do
      sign_in user
      user.update!(
        stripe_customer_id: "cus_existing",
        stripe_subscription_id: "sub_existing",
        stripe_plan_id: "plan_old"
      )
    end

    let(:update_params) { { id: user.id, plan_id: "plan_new" } }

    it "retrieves the existing Stripe customer" do
      allow(Stripe::Customer).to receive(:retrieve).and_return(stripe_customer)
      patch :update, params: update_params
      expect(Stripe::Customer).to have_received(:retrieve).with("cus_existing")
    end

    it "retrieves the existing subscription" do
      subscriptions = double
      allow(stripe_customer).to receive(:subscriptions).and_return(subscriptions)
      allow(subscriptions).to receive(:retrieve).and_return(stripe_subscription)
      patch :update, params: update_params
      expect(subscriptions).to have_received(:retrieve).with("sub_existing")
    end

    it "updates the subscription plan" do
      allow(stripe_subscription).to receive(:plan=)
      allow(stripe_subscription).to receive(:save)
      patch :update, params: update_params
      expect(stripe_subscription).to have_received(:plan=).with("plan_new")
      expect(stripe_subscription).to have_received(:save)
    end

    it "updates user with new stripe_plan_id" do
      patch :update, params: update_params
      expect(user.reload.stripe_plan_id).to eq("plan_basic")
    end

    it "sets new_supporter session flag" do
      patch :update, params: update_params
      expect(session[:new_supporter]).to be(true)
    end

    it "redirects to user profile" do
      patch :update, params: update_params
      expect(response).to redirect_to(user_path(user))
    end

    it "requires authentication" do
      sign_out user
      patch :update, params: update_params
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "private methods" do
    describe "#load_stripe_library" do
      it "sets @load_stripe_library to true" do
        sign_in user
        get :index
        expect(assigns(:load_stripe_library)).to be(true)
      end
    end
  end
end
