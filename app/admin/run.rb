# typed: false
# frozen_string_literal: true

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
      format("%.1f", run.wall_time) if run.wall_time
    end
    column :cpu_time do |run|
      format("%.1f", run.cpu_time) if run.cpu_time
    end
    actions
  end

  filter :scraper
  filter :owner
  filter :auto
  filter :started_at
  filter :finished_at
  filter :wall_time

  show do
    attributes_table do
      row :id
      row :scraper
      row :started_at
      row :finished_at
      row :status_code
      row :queued_at
      row :auto
      row :git_revision
      row :owner
      row :wall_time
      row :records_added
      row :records_removed
      row :records_changed
      row :records_unchanged
    end

    h2 "Console output"

    table do
      thead do
        tr do
          th "Stream"
          th "Text"
        end
      end
      tbody do
        run.log_lines.order("log_lines.id").each do |line|
          tr do
            td line.stream
            td sanitize(h(line.text).gsub("\n", "<br/>"))
          end
        end
      end
    end
  end
end
