ActiveAdmin.register Run do
  actions :index, :show

  index do
    id_column
    column :scraper
    column :owner do |run|
      link_to run.owner.nickname, admin_owner_path(run.owner)
    end
    column :auto
    column :started_at
    column :finished_at
    column :wall_time, sortable: :wall_time do |run|
      "%.1f" % run.wall_time
    end
    column :cpu_time do |run|
      "%.1f" % run.cpu_time
    end
    actions
  end

  filter :scraper
  filter :owner
  filter :auto
  filter :started_at
  filter :finished_at
  filter :wall_time
end
