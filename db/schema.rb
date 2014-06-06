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

ActiveRecord::Schema.define(version: 20140606055020) do

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "alerts", force: true do |t|
    t.integer  "user_id"
    t.integer  "watch_id"
    t.string   "watch_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "alerts", ["user_id"], name: "index_alerts_on_user_id", using: :btree
  add_index "alerts", ["watch_id"], name: "index_alerts_on_watch_id", using: :btree
  add_index "alerts", ["watch_type"], name: "index_alerts_on_watch_type", using: :btree

  create_table "api_queries", force: true do |t|
    t.string   "type"
    t.text     "query"
    t.integer  "scraper_id"
    t.integer  "owner_id"
    t.float    "utime"
    t.float    "stime"
    t.float    "wall_time"
    t.integer  "size"
    t.string   "format"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_queries", ["owner_id"], name: "index_api_queries_on_owner_id", using: :btree
  add_index "api_queries", ["scraper_id"], name: "index_api_queries_on_scraper_id", using: :btree

  create_table "connection_logs", force: true do |t|
    t.integer  "run_id"
    t.string   "method"
    t.string   "scheme"
    t.string   "host"
    t.text     "path"
    t.integer  "request_size"
    t.integer  "response_size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "connection_logs", ["host"], name: "index_connection_logs_on_host", using: :btree
  add_index "connection_logs", ["run_id"], name: "index_connection_logs_on_run_id", using: :btree

  create_table "contributions", force: true do |t|
    t.integer  "scraper_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contributions", ["scraper_id"], name: "index_contributions_on_scraper_id", using: :btree
  add_index "contributions", ["user_id"], name: "index_contributions_on_user_id", using: :btree

  create_table "create_scraper_progresses", force: true do |t|
    t.string   "message"
    t.integer  "progress"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "heading"
  end

  create_table "log_lines", force: true do |t|
    t.integer  "run_id"
    t.string   "stream"
    t.integer  "number"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "log_lines", ["number"], name: "index_log_lines_on_number", using: :btree
  add_index "log_lines", ["run_id"], name: "index_log_lines_on_run_id", using: :btree

  create_table "metrics", force: true do |t|
    t.float    "wall_time"
    t.float    "utime"
    t.float    "stime"
    t.integer  "maxrss"
    t.integer  "minflt"
    t.integer  "majflt"
    t.integer  "inblock"
    t.integer  "oublock"
    t.integer  "nvcsw"
    t.integer  "nivcsw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "run_id"
  end

  add_index "metrics", ["run_id"], name: "index_metrics_on_run_id", using: :btree

  create_table "organizations_users", force: true do |t|
    t.integer "organization_id"
    t.integer "user_id"
  end

  add_index "organizations_users", ["organization_id"], name: "index_organizations_users_on_organization_id", using: :btree
  add_index "organizations_users", ["user_id"], name: "index_organizations_users_on_user_id", using: :btree

  create_table "owners", force: true do |t|
    t.integer  "sign_in_count",      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "nickname"
    t.string   "access_token"
    t.string   "blog"
    t.string   "company"
    t.string   "email"
    t.string   "type"
    t.string   "gravatar_url"
    t.string   "api_key"
    t.boolean  "admin",              default: false, null: false
    t.boolean  "suspended",          default: false, null: false
    t.string   "feature_switches"
  end

  add_index "owners", ["api_key"], name: "index_owners_on_api_key", using: :btree
  add_index "owners", ["nickname"], name: "index_owners_on_nickname", using: :btree

  create_table "runs", force: true do |t|
    t.integer  "scraper_id"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status_code"
    t.datetime "queued_at"
    t.boolean  "auto",              default: false, null: false
    t.string   "git_revision"
    t.integer  "owner_id"
    t.float    "wall_time",         default: 0.0,   null: false
    t.integer  "tables_added"
    t.integer  "tables_removed"
    t.integer  "tables_changed"
    t.integer  "tables_unchanged"
    t.integer  "records_added"
    t.integer  "records_removed"
    t.integer  "records_changed"
    t.integer  "records_unchanged"
    t.string   "ip_address"
  end

  add_index "runs", ["owner_id"], name: "index_runs_on_owner_id", using: :btree
  add_index "runs", ["scraper_id"], name: "index_runs_on_scraper_id", using: :btree

  create_table "scrapers", force: true do |t|
    t.string   "name",                       default: "",    null: false
    t.string   "description"
    t.integer  "github_id"
    t.integer  "owner_id",                                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_name"
    t.string   "github_url"
    t.string   "git_url"
    t.boolean  "auto_run",                   default: false, null: false
    t.string   "scraperwiki_url"
    t.integer  "forked_by_id"
    t.integer  "repo_size",                  default: 0,     null: false
    t.integer  "sqlite_db_size",             default: 0,     null: false
    t.integer  "create_scraper_progress_id"
    t.string   "original_language"
  end

  add_index "scrapers", ["full_name"], name: "index_scrapers_on_full_name", using: :btree
  add_index "scrapers", ["owner_id"], name: "index_scrapers_on_owner_id", using: :btree

  create_table "variables", force: true do |t|
    t.string   "name"
    t.string   "value"
    t.integer  "scraper_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
