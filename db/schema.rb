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

ActiveRecord::Schema.define(version: 2022_09_19_011435) do

  create_table "active_admin_comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "author_id"
    t.string "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "alerts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "watch_id"
    t.string "watch_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_alerts_on_user_id"
    t.index ["watch_id"], name: "index_alerts_on_watch_id"
    t.index ["watch_type"], name: "index_alerts_on_watch_type"
  end

  create_table "api_queries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "type"
    t.text "query"
    t.integer "scraper_id"
    t.integer "owner_id"
    t.float "utime"
    t.float "stime"
    t.float "wall_time"
    t.integer "size"
    t.string "format"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_api_queries_on_created_at"
    t.index ["owner_id"], name: "index_api_queries_on_owner_id"
    t.index ["scraper_id"], name: "index_api_queries_on_scraper_id"
  end

  create_table "connection_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "run_id"
    t.integer "domain_id"
    t.datetime "created_at"
    t.index ["created_at"], name: "index_connection_logs_on_created_at"
    t.index ["domain_id"], name: "index_connection_logs_on_domain_id"
    t.index ["run_id"], name: "index_connection_logs_on_run_id"
  end

  create_table "contributions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "scraper_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["scraper_id"], name: "index_contributions_on_scraper_id"
    t.index ["user_id"], name: "index_contributions_on_user_id"
  end

  create_table "create_scraper_progresses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "message"
    t.integer "progress"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "heading"
  end

  create_table "domains", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "meta"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "title"
    t.index ["name"], name: "index_domains_on_name", unique: true
  end

  create_table "log_lines", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "run_id"
    t.string "stream"
    t.text "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "timestamp", precision: 6
    t.index ["run_id"], name: "index_log_lines_on_run_id"
    t.index ["timestamp"], name: "index_log_lines_on_timestamp"
  end

  create_table "metrics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.float "wall_time"
    t.float "utime"
    t.float "stime"
    t.integer "maxrss"
    t.integer "minflt"
    t.integer "majflt"
    t.integer "inblock"
    t.integer "oublock"
    t.integer "nvcsw"
    t.integer "nivcsw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "run_id"
    t.index ["run_id"], name: "index_metrics_on_run_id"
  end

  create_table "organizations_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "user_id"
    t.index ["organization_id"], name: "index_organizations_users_on_organization_id"
    t.index ["user_id"], name: "index_organizations_users_on_user_id"
  end

  create_table "owners", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "nickname"
    t.string "access_token"
    t.string "blog"
    t.string "company"
    t.string "email"
    t.string "type"
    t.string "gravatar_url"
    t.string "api_key"
    t.boolean "admin", default: false, null: false
    t.boolean "suspended", default: false, null: false
    t.string "feature_switches"
    t.datetime "remember_created_at"
    t.string "remember_token"
    t.string "stripe_customer_id"
    t.string "stripe_plan_id"
    t.string "stripe_subscription_id"
    t.string "location"
    t.datetime "alerted_at"
    t.index ["api_key"], name: "index_owners_on_api_key"
    t.index ["nickname"], name: "index_owners_on_nickname"
  end

  create_table "runs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "scraper_id"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "status_code"
    t.datetime "queued_at"
    t.boolean "auto", default: false, null: false
    t.string "git_revision"
    t.integer "owner_id", null: false
    t.float "wall_time", default: 0.0, null: false
    t.integer "tables_added"
    t.integer "tables_removed"
    t.integer "tables_changed"
    t.integer "tables_unchanged"
    t.integer "records_added"
    t.integer "records_removed"
    t.integer "records_changed"
    t.integer "records_unchanged"
    t.string "ip_address"
    t.integer "connection_logs_count"
    t.string "docker_image"
    t.index ["created_at"], name: "index_runs_on_created_at"
    t.index ["docker_image"], name: "index_runs_on_docker_image"
    t.index ["finished_at"], name: "index_runs_on_finished_at"
    t.index ["ip_address"], name: "index_runs_on_ip_address"
    t.index ["owner_id"], name: "index_runs_on_owner_id"
    t.index ["scraper_id", "status_code", "finished_at"], name: "index_runs_on_scraper_id_and_status_code_and_finished_at"
    t.index ["scraper_id"], name: "index_runs_on_scraper_id"
    t.index ["started_at"], name: "index_runs_on_started_at"
  end

  create_table "scrapers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "description"
    t.integer "github_id"
    t.integer "owner_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "full_name", null: false
    t.string "github_url"
    t.string "git_url"
    t.boolean "auto_run", default: false, null: false
    t.string "scraperwiki_url"
    t.integer "forked_by_id"
    t.string "original_language_key"
    t.integer "repo_size", default: 0, null: false
    t.bigint "sqlite_db_size", default: 0, null: false
    t.integer "create_scraper_progress_id"
    t.integer "memory_mb"
    t.boolean "private", default: false, null: false
    t.index ["create_scraper_progress_id"], name: "fk_rails_44c3dd8af8"
    t.index ["full_name"], name: "index_scrapers_on_full_name", unique: true
    t.index ["owner_id", "name"], name: "index_scrapers_on_owner_id_and_name", unique: true
    t.index ["owner_id"], name: "index_scrapers_on_owner_id"
  end

  create_table "site_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "settings"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variables", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "value", null: false
    t.integer "scraper_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["scraper_id"], name: "fk_rails_f537200e37"
  end

  create_table "webhook_deliveries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "webhook_id"
    t.integer "run_id"
    t.datetime "sent_at"
    t.integer "response_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["run_id"], name: "index_webhook_deliveries_on_run_id"
    t.index ["webhook_id"], name: "index_webhook_deliveries_on_webhook_id"
  end

  create_table "webhooks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "scraper_id"
    t.string "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["scraper_id", "url"], name: "index_webhooks_on_scraper_id_and_url", unique: true
    t.index ["scraper_id"], name: "index_webhooks_on_scraper_id"
  end

  add_foreign_key "api_queries", "scrapers"
  add_foreign_key "connection_logs", "domains"
  add_foreign_key "connection_logs", "runs"
  add_foreign_key "contributions", "scrapers"
  add_foreign_key "log_lines", "runs"
  add_foreign_key "metrics", "runs"
  add_foreign_key "runs", "scrapers"
  add_foreign_key "scrapers", "create_scraper_progresses"
  add_foreign_key "variables", "scrapers"
  add_foreign_key "webhook_deliveries", "runs"
  add_foreign_key "webhook_deliveries", "webhooks"
  add_foreign_key "webhooks", "scrapers"
end
