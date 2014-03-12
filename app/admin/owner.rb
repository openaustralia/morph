ActiveAdmin.register Owner do
  actions :index, :show

  index do
    column :gravatar do |owner|
      image_tag owner.gravatar_url, size: "50x50"
    end
    column :type
    column :nickname
    column :name

    actions
  end

  filter :type
  filter :nickname
  filter :name

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
