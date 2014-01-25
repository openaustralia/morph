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

ActiveRecord::Schema.define(version: 20140125020217) do

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

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
    t.string   "gravatar_id"
    t.string   "blog"
    t.string   "company"
    t.string   "email"
    t.string   "type"
    t.string   "gravatar_url"
  end

  create_table "runs", force: true do |t|
    t.integer  "scraper_id"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status_code"
    t.datetime "queued_at"
    t.boolean  "auto",         default: false, null: false
    t.string   "git_revision"
  end

  create_table "scrapers", force: true do |t|
    t.string   "name",                            null: false
    t.string   "description"
    t.integer  "github_id"
    t.integer  "owner_id",                        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_name"
    t.string   "github_url"
    t.string   "git_url"
    t.boolean  "auto_run",        default: false, null: false
    t.string   "scraperwiki_url"
    t.boolean  "forking",         default: false, null: false
    t.integer  "forked_by_id"
  end

end
