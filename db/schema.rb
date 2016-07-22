# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160722020602) do

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body",          limit: 65535
    t.string   "resource_id",   limit: 255,   null: false
    t.string   "resource_type", limit: 255,   null: false
    t.integer  "author_id",     limit: 4
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "alerts", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "watch_id",   limit: 4
    t.string   "watch_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "alerts", ["user_id"], name: "index_alerts_on_user_id", using: :btree
  add_index "alerts", ["watch_id"], name: "index_alerts_on_watch_id", using: :btree
  add_index "alerts", ["watch_type"], name: "index_alerts_on_watch_type", using: :btree

  create_table "api_queries", force: :cascade do |t|
    t.string   "type",       limit: 255
    t.text     "query",      limit: 65535
    t.integer  "scraper_id", limit: 4
    t.integer  "owner_id",   limit: 4
    t.float    "utime",      limit: 24
    t.float    "stime",      limit: 24
    t.float    "wall_time",  limit: 24
    t.integer  "size",       limit: 4
    t.string   "format",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_queries", ["created_at"], name: "index_api_queries_on_created_at", using: :btree
  add_index "api_queries", ["owner_id"], name: "index_api_queries_on_owner_id", using: :btree
  add_index "api_queries", ["scraper_id"], name: "index_api_queries_on_scraper_id", using: :btree

  create_table "connection_logs", force: :cascade do |t|
    t.integer  "run_id",        limit: 4
    t.string   "method",        limit: 255
    t.string   "scheme",        limit: 255
    t.text     "path",          limit: 65535
    t.integer  "request_size",  limit: 4
    t.integer  "response_size", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "domain_id",     limit: 4
    t.integer  "response_code", limit: 4
  end

  add_index "connection_logs", ["created_at"], name: "index_connection_logs_on_created_at", using: :btree
  add_index "connection_logs", ["domain_id"], name: "index_connection_logs_on_domain_id", using: :btree
  add_index "connection_logs", ["run_id"], name: "index_connection_logs_on_run_id", using: :btree

  create_table "contributions", force: :cascade do |t|
    t.integer  "scraper_id", limit: 4
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contributions", ["scraper_id"], name: "index_contributions_on_scraper_id", using: :btree
  add_index "contributions", ["user_id"], name: "index_contributions_on_user_id", using: :btree

  create_table "create_scraper_progresses", force: :cascade do |t|
    t.string   "message",    limit: 255
    t.integer  "progress",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "heading",    limit: 255
  end

  create_table "domains", force: :cascade do |t|
    t.string   "name",       limit: 255,   null: false
    t.text     "meta",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "title",      limit: 65535
  end

  add_index "domains", ["name"], name: "index_domains_on_name", unique: true, using: :btree

  create_table "log_lines", force: :cascade do |t|
    t.integer  "run_id",     limit: 4
    t.string   "stream",     limit: 255
    t.integer  "number",     limit: 4
    t.text     "text",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "log_lines", ["number"], name: "index_log_lines_on_number", using: :btree
  add_index "log_lines", ["run_id"], name: "index_log_lines_on_run_id", using: :btree

  create_table "metrics", force: :cascade do |t|
    t.float    "wall_time",  limit: 24
    t.float    "utime",      limit: 24
    t.float    "stime",      limit: 24
    t.integer  "maxrss",     limit: 4
    t.integer  "minflt",     limit: 4
    t.integer  "majflt",     limit: 4
    t.integer  "inblock",    limit: 4
    t.integer  "oublock",    limit: 4
    t.integer  "nvcsw",      limit: 4
    t.integer  "nivcsw",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "run_id",     limit: 4
  end

  add_index "metrics", ["run_id"], name: "index_metrics_on_run_id", using: :btree

  create_table "organizations_users", force: :cascade do |t|
    t.integer "organization_id", limit: 4
    t.integer "user_id",         limit: 4
  end

  add_index "organizations_users", ["organization_id"], name: "index_organizations_users_on_organization_id", using: :btree
  add_index "organizations_users", ["user_id"], name: "index_organizations_users_on_user_id", using: :btree

  create_table "owners", force: :cascade do |t|
    t.integer  "sign_in_count",          limit: 4,   default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider",               limit: 255
    t.string   "uid",                    limit: 255
    t.string   "name",                   limit: 255
    t.string   "nickname",               limit: 255
    t.string   "access_token",           limit: 255
    t.string   "blog",                   limit: 255
    t.string   "company",                limit: 255
    t.string   "email",                  limit: 255
    t.string   "type",                   limit: 255
    t.string   "gravatar_url",           limit: 255
    t.string   "api_key",                limit: 255
    t.boolean  "admin",                              default: false, null: false
    t.boolean  "suspended",                          default: false, null: false
    t.string   "feature_switches",       limit: 255
    t.datetime "remember_created_at"
    t.string   "remember_token",         limit: 255
    t.string   "stripe_customer_id",     limit: 255
    t.string   "stripe_plan_id",         limit: 255
    t.string   "stripe_subscription_id", limit: 255
    t.string   "location",               limit: 255
    t.datetime "alerted_at"
  end

  add_index "owners", ["api_key"], name: "index_owners_on_api_key", using: :btree
  add_index "owners", ["nickname"], name: "index_owners_on_nickname", using: :btree

  create_table "runs", force: :cascade do |t|
    t.integer  "scraper_id",            limit: 4
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status_code",           limit: 4
    t.datetime "queued_at"
    t.boolean  "auto",                              default: false, null: false
    t.string   "git_revision",          limit: 255
    t.integer  "owner_id",              limit: 4
    t.float    "wall_time",             limit: 24,  default: 0.0,   null: false
    t.integer  "tables_added",          limit: 4
    t.integer  "tables_removed",        limit: 4
    t.integer  "tables_changed",        limit: 4
    t.integer  "tables_unchanged",      limit: 4
    t.integer  "records_added",         limit: 4
    t.integer  "records_removed",       limit: 4
    t.integer  "records_changed",       limit: 4
    t.integer  "records_unchanged",     limit: 4
    t.string   "ip_address",            limit: 255
    t.integer  "connection_logs_count", limit: 4
    t.string   "docker_image",          limit: 255
  end

  add_index "runs", ["created_at"], name: "index_runs_on_created_at", using: :btree
  add_index "runs", ["docker_image"], name: "index_runs_on_docker_image", using: :btree
  add_index "runs", ["finished_at"], name: "index_runs_on_finished_at", using: :btree
  add_index "runs", ["owner_id"], name: "index_runs_on_owner_id", using: :btree
  add_index "runs", ["scraper_id"], name: "index_runs_on_scraper_id", using: :btree

  create_table "scrapers", force: :cascade do |t|
    t.string   "name",                       limit: 255, default: "",    null: false
    t.string   "description",                limit: 255
    t.integer  "github_id",                  limit: 4
    t.integer  "owner_id",                   limit: 4,                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_name",                  limit: 255
    t.string   "github_url",                 limit: 255
    t.string   "git_url",                    limit: 255
    t.boolean  "auto_run",                               default: false, null: false
    t.string   "scraperwiki_url",            limit: 255
    t.integer  "forked_by_id",               limit: 4
    t.string   "original_language_key",      limit: 255
    t.integer  "repo_size",                  limit: 4,   default: 0,     null: false
    t.integer  "sqlite_db_size",             limit: 8,   default: 0,     null: false
    t.integer  "create_scraper_progress_id", limit: 4
  end

  add_index "scrapers", ["full_name"], name: "index_scrapers_on_full_name", using: :btree
  add_index "scrapers", ["owner_id"], name: "index_scrapers_on_owner_id", using: :btree

  create_table "site_settings", force: :cascade do |t|
    t.string   "settings",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variables", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.text     "value",      limit: 65535
    t.integer  "scraper_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer  "webhook_id",    limit: 4
    t.integer  "run_id",        limit: 4
    t.datetime "sent_at"
    t.integer  "response_code", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "webhook_deliveries", ["run_id"], name: "index_webhook_deliveries_on_run_id", using: :btree
  add_index "webhook_deliveries", ["webhook_id"], name: "index_webhook_deliveries_on_webhook_id", using: :btree

  create_table "webhooks", force: :cascade do |t|
    t.integer  "scraper_id", limit: 4
    t.string   "url",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "webhooks", ["scraper_id"], name: "index_webhooks_on_scraper_id", using: :btree

end
