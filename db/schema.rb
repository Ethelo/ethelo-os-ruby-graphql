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

ActiveRecord::Schema.define(version: 20242201145051) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"

  create_table "cached_calculation_variables", id: false, force: :cascade do |t|
    t.bigint "cached_variable_id"
    t.bigint "cached_calculation_id"
    t.integer "cache_id"
    t.bigint "decision_id"
    t.bigint "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cache_id"], name: "index_cached_calculation_variables_on_cache_id"
    t.index ["cached_calculation_id", "cached_variable_id"], name: "calculation_and_variable_unique", unique: true
    t.index ["cached_calculation_id"], name: "index_cached_calculation_variables_on_cached_calculation_id"
    t.index ["cached_decision_id"], name: "index_cached_calculation_variables_on_cached_decision_id"
    t.index ["cached_variable_id"], name: "index_cached_calculation_variables_on_cached_variable_id"
    t.index ["decision_id"], name: "index_cached_calculation_variables_on_decision_id"
  end

  create_table "cached_calculations", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "expression"
    t.boolean "public", default: false
    t.string "display_hint"
    t.integer "cache_id"
    t.bigint "decision_id"
    t.bigint "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sort", default: 0, null: false
    t.string "personal_results_title"
    t.index ["cache_id"], name: "index_cached_calculations_on_cache_id"
    t.index ["cached_decision_id"], name: "index_cached_calculations_on_cached_decision_id"
    t.index ["decision_id"], name: "index_cached_calculations_on_decision_id"
  end

  create_table "cached_constraints", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "operator"
    t.float "value"
    t.float "between_high"
    t.float "between_low"
    t.boolean "enabled"
    t.integer "cache_id"
    t.bigint "decision_id"
    t.bigint "cached_decision_id"
    t.bigint "cached_option_filter_id"
    t.bigint "cached_calculation_id"
    t.bigint "cached_variable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "optional", default: false
    t.boolean "relaxable", default: false, null: false
    t.index ["cached_calculation_id"], name: "index_cached_constraints_on_cached_calculation_id"
    t.index ["cached_decision_id"], name: "index_cached_constraints_on_cached_decision_id"
    t.index ["cached_option_filter_id"], name: "index_cached_constraints_on_cached_option_filter_id"
    t.index ["cached_variable_id"], name: "index_cached_constraints_on_cached_variable_id"
    t.index ["decision_id"], name: "index_cached_constraints_on_decision_id"
  end

  create_table "cached_criteria", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "info"
    t.string "slug"
    t.integer "bins"
    t.integer "weighting"
    t.boolean "support_only"
    t.integer "cache_id"
    t.integer "decision_id"
    t.integer "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false, null: false
    t.boolean "apply_participant_weights", default: true
    t.integer "sort", default: 0, null: false
    t.index ["cache_id"], name: "index_cached_criteria_on_cache_id"
    t.index ["cached_decision_id"], name: "index_cached_criteria_on_cached_decision_id"
    t.index ["decision_id"], name: "index_cached_criteria_on_decision_id"
  end

  create_table "cached_decisions", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "info"
    t.string "slug"
    t.integer "cache_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false, null: false
    t.index ["cache_id"], name: "index_cached_decisions_on_cache_id"
    t.index ["copyable"], name: "index_cached_decisions_on_copyable"
  end

  create_table "cached_option_categories", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "info"
    t.string "slug"
    t.integer "weighting"
    t.integer "cache_id"
    t.integer "decision_id"
    t.integer "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false, null: false
    t.boolean "xor", default: false
    t.string "scoring_mode"
    t.integer "triangle_base", default: 3
    t.boolean "apply_participant_weights", default: true
    t.bigint "primary_detail_id"
    t.string "voting_style", default: "one"
    t.bigint "default_low_option_id"
    t.bigint "default_high_option_id"
    t.integer "sort", default: 0, null: false
    t.float "budget_percent"
    t.float "flat_fee"
    t.boolean "vote_on_percent", default: true
    t.string "results_title"
    t.boolean "quadratic", default: false, null: false
    t.string "keywords"
    t.index ["cache_id"], name: "index_cached_option_categories_on_cache_id"
    t.index ["cached_decision_id"], name: "index_cached_option_categories_on_cached_decision_id"
    t.index ["decision_id"], name: "index_cached_option_categories_on_decision_id"
    t.index ["default_high_option_id"], name: "index_cached_option_categories_on_default_high_option_id"
    t.index ["default_low_option_id"], name: "index_cached_option_categories_on_default_low_option_id"
    t.index ["primary_detail_id"], name: "index_cached_option_categories_on_primary_detail_id"
  end

  create_table "cached_option_detail_values", id: false, force: :cascade do |t|
    t.integer "cached_option_id"
    t.integer "cached_option_detail_id"
    t.string "value"
    t.integer "cache_id"
    t.integer "decision_id"
    t.integer "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cache_id"], name: "index_cached_option_detail_values_on_cache_id"
    t.index ["cached_decision_id"], name: "index_cached_option_detail_values_on_cached_decision_id"
    t.index ["cached_option_detail_id"], name: "index_cached_option_detail_values_on_cached_option_detail_id"
    t.index ["cached_option_id", "cached_option_detail_id"], name: "option_id_and_option_detail_unique", unique: true
    t.index ["cached_option_id"], name: "index_cached_option_detail_values_on_cached_option_id"
    t.index ["decision_id"], name: "index_cached_option_detail_values_on_decision_id"
  end

  create_table "cached_option_details", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "format"
    t.boolean "public", default: false
    t.string "input_hint"
    t.string "display_hint"
    t.integer "cache_id"
    t.integer "decision_id"
    t.integer "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sort", default: 0, null: false
    t.index ["cache_id"], name: "index_cached_option_details_on_cache_id"
    t.index ["cached_decision_id"], name: "index_cached_option_details_on_cached_decision_id"
    t.index ["decision_id"], name: "index_cached_option_details_on_decision_id"
  end

  create_table "cached_option_filters", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "match_mode"
    t.string "match_value"
    t.bigint "cached_option_detail_id"
    t.bigint "cached_option_category_id"
    t.integer "option_count"
    t.integer "cache_id"
    t.bigint "decision_id"
    t.bigint "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cache_id"], name: "index_cached_option_filters_on_cache_id"
    t.index ["cached_decision_id"], name: "index_cached_option_filters_on_cached_decision_id"
    t.index ["cached_option_category_id"], name: "index_cached_option_filters_on_cached_option_category_id"
    t.index ["cached_option_detail_id"], name: "index_cached_option_filters_on_cached_option_detail_id"
    t.index ["decision_id"], name: "index_cached_option_filters_on_decision_id"
  end

  create_table "cached_options", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "info"
    t.string "slug"
    t.boolean "enabled"
    t.integer "cache_id"
    t.integer "decision_id"
    t.integer "cached_decision_id"
    t.integer "cached_option_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false, null: false
    t.integer "sort", default: 0, null: false
    t.string "results_title"
    t.boolean "determinative", default: false, null: false
    t.index ["cache_id"], name: "index_cached_options_on_cache_id"
    t.index ["cached_decision_id"], name: "index_cached_options_on_cached_decision_id"
    t.index ["cached_option_category_id"], name: "index_cached_options_on_cached_option_category_id"
    t.index ["decision_id"], name: "index_cached_options_on_decision_id"
  end

  create_table "cached_scenario_configs", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.integer "max_scenarios"
    t.integer "bins"
    t.integer "ttl"
    t.boolean "support_only"
    t.float "collective_identity"
    t.float "tipping_point"
    t.boolean "enabled"
    t.integer "cache_id"
    t.bigint "decision_id"
    t.bigint "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "skip_solver", default: false, null: false
    t.boolean "normalize_influents", default: false, null: false
    t.boolean "per_option_satisfaction", default: false, null: false
    t.integer "solve_interval", default: 0, null: false
    t.boolean "normalize_satisfaction", default: true
    t.boolean "quadratic", default: false, null: false
    t.integer "positive_seed_votes_sum"
    t.integer "quad_user_seeds"
    t.integer "quad_total_available"
    t.integer "quad_cutoff"
    t.integer "quad_max_allocation"
    t.integer "quad_round_to"
    t.float "quad_seed_percent"
    t.float "quad_vote_percent"
    t.index ["cached_decision_id"], name: "index_cached_scenario_configs_on_cached_decision_id"
    t.index ["decision_id"], name: "index_cached_scenario_configs_on_decision_id"
  end

  create_table "cached_variables", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "method"
    t.bigint "cached_option_detail_id"
    t.bigint "cached_option_filter_id"
    t.integer "calculation_count"
    t.integer "cache_id"
    t.bigint "decision_id"
    t.bigint "cached_decision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cache_id"], name: "index_cached_variables_on_cache_id"
    t.index ["cached_decision_id"], name: "index_cached_variables_on_cached_decision_id"
    t.index ["cached_option_detail_id"], name: "index_cached_variables_on_cached_option_detail_id"
    t.index ["cached_option_filter_id"], name: "index_cached_variables_on_cached_option_filter_id"
    t.index ["decision_id"], name: "index_cached_variables_on_decision_id"
  end

  create_table "decision_users", force: :cascade do |t|
    t.bigint "decision_id"
    t.decimal "influence", precision: 10, scale: 5, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cached_repo_id"
    t.index ["decision_id"], name: "index_decision_users_on_decision_id"
  end

  create_table "decisions", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "info"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cached_decision_id"
    t.datetime "last_published"
    t.datetime "last_solved_at"
    t.index "lower((slug)::text)", name: "idx_decision_slug"
    t.index ["cached_decision_id"], name: "index_decisions_on_cached_decision_id"
  end

  add_foreign_key "cached_calculation_variables", "cached_calculations", on_delete: :cascade
  add_foreign_key "cached_calculation_variables", "cached_variables", on_delete: :cascade
  add_foreign_key "cached_option_categories", "cached_option_details", column: "primary_detail_id", on_delete: :nullify
  add_foreign_key "cached_option_categories", "cached_options", column: "default_high_option_id", on_delete: :nullify
  add_foreign_key "cached_option_categories", "cached_options", column: "default_low_option_id", on_delete: :nullify
  add_foreign_key "cached_option_detail_values", "cached_option_details", on_delete: :cascade
  add_foreign_key "cached_option_detail_values", "cached_options", on_delete: :cascade
  add_foreign_key "decision_users", "decisions", on_delete: :cascade
  add_foreign_key "decisions", "cached_decisions"

end
