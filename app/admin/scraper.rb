# typed: false
# frozen_string_literal: true

ActiveAdmin.register Scraper do
  actions :index

  index do
    column :full_name do |scraper|
      link_to scraper.full_name, scraper
    end
    column :description
    column :updated_at
    column :repo_size
    column :sqlite_db_size
    column :sqlite_total_rows
    column :auto_run
  end

  csv do
    column :full_name
    column :description
    column :updated_at
    column :repo_size
    column :sqlite_db_size
    column :sqlite_total_rows
    column :auto_run
  end

  filter :full_name
  filter :description
  filter :updated_at
  filter :repo_size
  filter :sqlite_db_size
  filter :owner
end
