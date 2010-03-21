# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100321204236) do

  create_table "collection_translations", :force => true do |t|
    t.integer  "collection_id"
    t.string   "locale"
    t.string   "caption"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "collection_translations", ["collection_id"], :name => "index_collection_translations_on_collection_id"

  create_table "collections", :force => true do |t|
    t.string   "address"
    t.string   "address2"
    t.string   "city"
    t.string   "state_province"
    t.string   "postal_code"
    t.string   "telephone"
    t.string   "email"
    t.string   "website"
    t.string   "contact"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_translations", :force => true do |t|
    t.integer  "item_id"
    t.string   "locale"
    t.string   "display_date"
    t.text     "description"
    t.string   "title"
    t.string   "caption"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_translations", ["item_id"], :name => "index_item_translations_on_item_id"
  add_index "item_translations", ["title"], :name => "title"

  create_table "items", :force => true do |t|
    t.string   "accession_num"
    t.string   "olivia_id"
    t.string   "urn"
    t.integer  "creator_id"
    t.integer  "owner_id"
    t.integer  "collection_id"
    t.integer  "pages"
    t.integer  "format_id"
    t.date     "sort_date"
    t.string   "dimensions"
    t.text     "notes"
    t.integer  "place_id"
    t.boolean  "publish"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["accession_num"], :name => "accession_num", :unique => true
  add_index "items", ["collection_id"], :name => "collection_id"
  add_index "items", ["olivia_id"], :name => "olivia_id"
  add_index "items", ["publish"], :name => "publish"
  add_index "items", ["sort_date"], :name => "sort_date"

  create_table "people", :force => true do |t|
    t.string   "loc_name"
    t.date     "dob"
    t.date     "dod"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "person_translations", :force => true do |t|
    t.integer  "person_id"
    t.string   "locale"
    t.text     "description"
    t.string   "vitals"
    t.string   "birth_place"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "person_translations", ["person_id"], :name => "index_person_translations_on_person_id"

end
