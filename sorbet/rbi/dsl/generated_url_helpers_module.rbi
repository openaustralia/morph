# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `GeneratedUrlHelpersModule`.
# Please instead update this file by running `bin/tapioca dsl GeneratedUrlHelpersModule`.

module GeneratedUrlHelpersModule
  include ::ActionDispatch::Routing::UrlFor
  include ::ActionDispatch::Routing::PolymorphicRoutes

  sig { params(args: T.untyped).returns(String) }
  def admin_api_queries_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_api_query_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_comment_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_comments_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_dashboard_toggle_read_only_mode_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_dashboard_update_maximum_concurrent_scrapers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_dashboard_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_docker_containers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_docker_images_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_owner_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_owners_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_root_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_run_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_runs_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_scraper_queue_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_scrapers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_sidekiq_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def api_documentation_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def api_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def batch_action_admin_api_queries_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def batch_action_admin_owners_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def batch_action_admin_runs_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def batch_action_admin_scrapers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def clear_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def connection_logs_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def create_one_time_supporters_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def data_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def destroy_user_session_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def discourse_sso_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def documentation_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def documentation_nodejs_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def documentation_perl_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def documentation_php_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def documentation_python_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def documentation_ruby_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_admin_owner_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def github_app_documentation_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def github_form_scrapers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def github_new_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def github_scrapers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def history_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def language_version_documentation_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def libraries_documentation_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_supporter_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_session_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def organization_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def owner_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def pricing_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_blob_representation_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_blob_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_direct_uploads_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_disk_service_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_properties_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_routes_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_mailers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_representation_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_service_blob_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def reset_key_owner_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def root_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def run_locally_documentation_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def run_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def run_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def running_scrapers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def scrapers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def scraping_javascript_sites_documentation_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def secret_values_documentation_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_owner_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def sidekiq_web_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def stats_users_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def stop_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def supporter_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def supporters_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def sync_refetch_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def toggle_privacy_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def toggle_read_only_mode_admin_site_settings_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def update_maximum_concurrent_scrapers_admin_site_settings_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def update_rails_disk_service_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_github_omniauth_authorize_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_github_omniauth_callback_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def users_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def watch_owner_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def watch_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def watchers_scraper_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def watching_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def webhooks_documentation_index_url(*args); end
end
