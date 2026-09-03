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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_130000) do
  create_table "active_hashcash_reputation_ipv4s", primary_key: ["range_start", "range_end"], force: :cascade do |t|
    t.integer "abuse_score", limit: 1, default: 0, null: false
    t.integer "anonymous_score", limit: 1, default: 0, null: false
    t.integer "attack_score", limit: 1, default: 0, null: false
    t.binary "range_end", limit: 4, null: false
    t.binary "range_start", limit: 4, null: false
  end

  create_table "active_hashcash_reputation_locks", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "locked_at", precision: nil
    t.string "source", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["source"], name: "index_active_hashcash_reputation_locks_on_source", unique: true
  end

  create_table "active_hashcash_stamps", force: :cascade do |t|
    t.integer "bits", null: false
    t.json "context"
    t.string "counter", null: false
    t.datetime "created_at", precision: nil, null: false
    t.date "date", null: false
    t.string "ext", null: false
    t.string "ip_address"
    t.string "rand", null: false
    t.string "request_path"
    t.string "resource", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "version", null: false
    t.index ["counter", "rand", "date", "resource", "bits", "version", "ext"], name: "index_active_hashcash_stamps_unique", unique: true
    t.index ["ip_address", "created_at"], name: "index_active_hashcash_stamps_on_ip_address_and_created_at", where: "ip_address IS NOT NULL"
  end
end
