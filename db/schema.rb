# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_21_181839) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "idx_events_date_desc", order: :desc
    t.index ["name"], name: "index_events_on_name", unique: true
  end

  create_table "fight_stats", force: :cascade do |t|
    t.bigint "fight_id", null: false
    t.bigint "fighter_id", null: false
    t.integer "round"
    t.integer "knockdowns"
    t.integer "significant_strikes"
    t.integer "significant_strikes_attempted"
    t.integer "total_strikes"
    t.integer "total_strikes_attempted"
    t.integer "takedowns"
    t.integer "takedowns_attempted"
    t.integer "submission_attempts"
    t.integer "reversals"
    t.integer "control_time_seconds"
    t.integer "head_strikes"
    t.integer "head_strikes_attempted"
    t.integer "body_strikes"
    t.integer "body_strikes_attempted"
    t.integer "leg_strikes"
    t.integer "leg_strikes_attempted"
    t.integer "distance_strikes"
    t.integer "distance_strikes_attempted"
    t.integer "clinch_strikes"
    t.integer "clinch_strikes_attempted"
    t.integer "ground_strikes"
    t.integer "ground_strikes_attempted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fight_id"], name: "index_fight_stats_on_fight_id"
    t.index ["fighter_id", "fight_id"], name: "index_fight_stats_on_fighter_id_and_fight_id"
    t.index ["fighter_id"], name: "index_fight_stats_on_fighter_id"
  end

  create_table "fighters", force: :cascade do |t|
    t.string "name", null: false
    t.integer "height_in_inches"
    t.integer "reach_in_inches"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "idx_fighters_name_lower"
    t.index ["name"], name: "idx_fighters_name"
    t.index ["name"], name: "idx_fighters_name_gin", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "fights", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "bout"
    t.string "outcome"
    t.string "weight_class"
    t.string "method"
    t.integer "round"
    t.string "time"
    t.string "time_format"
    t.string "referee"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_fights_on_event_id"
  end

  add_foreign_key "fight_stats", "fighters"
  add_foreign_key "fight_stats", "fights"
  add_foreign_key "fights", "events"
end
