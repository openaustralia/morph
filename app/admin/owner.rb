# typed: false
# frozen_string_literal: true

ActiveAdmin.register Owner do
  actions :index, :show, :edit, :update

  permit_params :admin, :suspended, :stripe_plan_id

  index do
    column :gravatar do |owner|
      image_url = owner.gravatar_url
      # Can't style the images using bootstrap because we're in the admin interface
      image_tag image_url, size: "50x50" if image_url
    end
    column :type
    column :nickname
    column :name

    column :scrapers do |owner|
      owner.scrapers.count
    end
    column :wall_time do |owner|
      owner.wall_time.to_i
    end
    column :cpu_time do |owner|
      owner.cpu_time.to_i
    end
    column :total_disk_usage do |owner|
      number_to_human_size(owner.total_disk_usage)
    end

    actions defaults: false do |owner|
      a link_to "View", admin_owner_path(owner)
      a link_to "Edit", edit_admin_owner_path(owner) if owner.user?
    end
  end

  filter :type
  filter :nickname
  filter :name
  filter :stripe_plan_id, as: :select, collection: Plan.all_stripe_plan_ids

  form do
    inputs "Permissions" do
      input :admin
      input :suspended
    end
    inputs "Supporter" do
      input :stripe_plan_id, as: :select, collection: Plan.all_stripe_plan_ids
    end
    actions
  end

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # permit_params :list, :of, :attributes, :on, :model
  #
  # or
  #
  # permit_params do
  #  permitted = [:permitted, :attributes]
  #  permitted << :other if resource.something?
  #  permitted
  # end
end
