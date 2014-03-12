ActiveAdmin.register Owner do
  actions :index, :show

  index do
    column :gravatar do |owner|
      image_tag owner.gravatar_url, size: "50x50"
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
