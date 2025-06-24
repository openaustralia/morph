class UpdateStripePlanIds < ActiveRecord::Migration[4.2]
  def change
    User.where.not(stripe_plan_id: nil).each do |user|
      user.update stripe_plan_id: "morph_#{user.stripe_plan_id}" unless user.stripe_plan_id.blank?
    end
  end
end
