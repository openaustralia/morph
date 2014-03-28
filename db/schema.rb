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

ActiveRecord::Schema.define(version: 20140328092932) do

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

  create_table "api_queries", force: true do |t|
    t.string   "type"
    t.string   "query"
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

  create_table "contributions", force: true do |t|
    t.integer  "scraper_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "log_lines", force: true do |t|
    t.integer  "run_id"
    t.string   "stream"
    t.integer  "number"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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

  create_table "organizations_users", force: true do |t|
    t.integer "organization_id"
    t.integer "user_id"
  end

  create_table "owners", force: true do |t|
    t.integer  "sign_in_count",      default: 0, null: false
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
  end

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
  end

  create_table "scrapers", force: true do |t|
    t.string   "name",              default: "",    null: false
    t.string   "description"
    t.integer  "github_id"
    t.integer  "owner_id",                          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_name"
    t.string   "github_url"
    t.string   "git_url"
    t.boolean  "auto_run",          default: false, null: false
    t.string   "scraperwiki_url"
    t.boolean  "forking",           default: false, null: false
    t.integer  "forked_by_id"
    t.string   "forking_message"
    t.integer  "forking_progress"
    t.string   "original_language"
    t.integer  "repo_size",         default: 0,     null: false
    t.integer  "sqlite_db_size",    default: 0,     null: false
  end

end
