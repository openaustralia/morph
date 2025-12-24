# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: scrapers
#
#  id                         :integer          not null, primary key
#  auto_run                   :boolean          default(FALSE), not null
#  description                :string(255)
#  full_name                  :string(255)      not null
#  git_url                    :string(255)
#  github_url                 :string(255)
#  memory_mb                  :integer
#  name                       :string(255)      default(""), not null
#  original_language_key      :string(255)
#  private                    :boolean          default(FALSE), not null
#  repo_size                  :integer          default(0), not null
#  scraperwiki_url            :string(255)
#  sqlite_db_size             :bigint           default(0), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  create_scraper_progress_id :integer
#  forked_by_id               :integer
#  github_id                  :integer
#  owner_id                   :integer          not null
#
# Indexes
#
#  fk_rails_44c3dd8af8                  (create_scraper_progress_id)
#  index_scrapers_on_full_name          (full_name) UNIQUE
#  index_scrapers_on_owner_id           (owner_id)
#  index_scrapers_on_owner_id_and_name  (owner_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (create_scraper_progress_id => create_scraper_progresses.id)


require "spec_helper"

def just_for_navigating
  require_relative "scraper/scraper_class_methods_spec"       # Class methods (.running, .new_from_github)
  require_relative "scraper/scraper_validations_spec"         # All validations with GitHub stubbing
  require_relative "scraper/scraper_queries_metrics_spec"     # Search, metrics, calculations, queries
  require_relative "scraper/scraper_files_paths_spec"         # File operations, paths, README, platform
  require_relative "scraper/scraper_associations_runs_spec"   # Associations, runs, webhooks, legacy tests
end

# This spec just contains navigation links to the actual tests in the never actually run method above.
# Ctrl-Click on the list in the just_for_navigating method above to navigate
#
# Run specific test files:
#   rspec spec/models/scraper/validations_spec.rb
#
# Or run all scraper tests:
#   rspec spec/models/scraper/

# rubocop:disable Lint/EmptyBlock, RSpec/EmptyExampleGroup
describe Scraper do
end
# rubocop:enable Lint/EmptyBlock, RSpec/EmptyExampleGroup
