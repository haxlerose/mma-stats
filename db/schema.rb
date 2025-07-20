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

ActiveRecord::Schema[8.0].define(version: 2025_07_20_131442) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_events_on_name", unique: true
  end

  create_table "fighters", force: :cascade do |t|
    t.string "name", null: false
    t.integer "height_in_inches"
    t.integer "reach_in_inches"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
